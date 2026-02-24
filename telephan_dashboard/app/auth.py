import json
import os
from functools import wraps
from flask import Blueprint, render_template, redirect, url_for, session, request, flash
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField
from wtforms.validators import DataRequired
import bcrypt
from sqlalchemy import text
from . import db
import csv
from datetime import datetime

# Initialisation du Blueprint
auth_bp = Blueprint("auth", __name__)

USERS_FILE = os.path.join("instance", "users.json")

# --- Fonctions utilitaires JSON ---
def _load_users():
    if not os.path.exists(USERS_FILE):
        return {}
    with open(USERS_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def _verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))

# --- Décorateurs ---
def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("user"):
            return redirect(url_for("auth.login", next=request.path))
        return view(*args, **kwargs)
    return wrapped

# --- Formulaire ---
class LoginForm(FlaskForm):
    username = StringField("Identifiant", validators=[DataRequired()])
    password = PasswordField("Mot de passe", validators=[DataRequired()])

# --- Routes ---
@auth_bp.get("/")
def root():
    return redirect(url_for("auth.home"))

@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        users = _load_users()
        username = form.username.data.strip()
        user = users.get(username)
        if user and _verify_password(form.password.data, user["password_hash"]):
            session.clear()
            session["user"] = {"username": username, "role": user.get("role", "lecteur")}
            return redirect(url_for("auth.home"))
        flash("Identifiants invalides.", "error")
    return render_template("login.html", form=form)

@auth_bp.get("/logout")
def logout():
    session.clear()
    return redirect(url_for("auth.login"))

@auth_bp.get("/home")
@login_required
def home():
    return render_template("home.html", user=session["user"])

@auth_bp.get("/qualite")
@login_required
def qualite_page():
    """Page Qualité : Pareto, Taux de panne et Énergie"""
    success_kpi = {"taux": 0, "nb": 0, "total": 0}
    pareto_data_formatted = []
    energy_data_formatted = [] # <--- CETTE VARIABLE MANQUAIT SUREMENT
    taux_panne = 0
    couleur_panne = "var(--good)"

    try:
        # 1. Pareto et KPI de succès
        query_pareto = text("""
            SELECT Categorie, Quantite, Pourcentage_Courbe, Total_General 
            FROM MES4_Analysis.V_Pareto_Global
            ORDER BY Quantite DESC
        """)
        results_pareto = db.session.execute(query_pareto).fetchall()
        
        if results_pareto:
            for row in results_pareto:
                categorie = str(row[0] or "Erreur")
                quantite = int(row[1] or 0)
                total_gen = int(row[3] or 0)
                pct_indiv = float((quantite / total_gen * 100)) if total_gen > 0 else 0.0
                is_ok = "OK" in categorie.upper() or "CONFORME" in categorie.upper()
                
                if is_ok:
                    success_kpi = {"nb": quantite, "total": total_gen, "taux": round(pct_indiv, 1)}

                pareto_data_formatted.append({
                    "label": categorie,
                    "qty": quantite,
                    "pct": round(pct_indiv, 1),
                    "cumul": float(row[2] or 0.0),
                    "is_ok": is_ok
                })

        # 2. Taux d'arrêt (Chiffre Spot)
        query_panne = text("SELECT Taux_Arret_Panne_Pourcentage FROM MES4_Analysis.V_Taux_Panne_Par_Jour LIMIT 1")
        res_panne = db.session.execute(query_panne).fetchone()
        if res_panne:
            taux_panne = float(res_panne[0] or 0.0)
            if taux_panne >= 50: couleur_panne = "var(--bad)"
            elif taux_panne >= 20: couleur_panne = "#ff9f43"

        # 3. Énergie (C'est cette partie qui corrige votre erreur 500)
        query_energy = text("SELECT Machine, Conso_Elec_Totale, Conso_Air_Total FROM MES4_Analysis.V_Conso_Energetique_Reelle")
        res_energy = db.session.execute(query_energy).fetchall()
        for r in res_energy:
            energy_data_formatted.append({
                "machine": str(r[0]), 
                "elec": float(r[1] or 0), 
                "air": float(r[2] or 0)
            })

    except Exception as e:
        print(f"Erreur SQL Qualité : {e}")

    # ATTENTION : energy_data=energy_data_formatted doit être présent ici !
    return render_template("qualite.html", 
                           user=session["user"], 
                           success_kpi=success_kpi, 
                           pareto_data=pareto_data_formatted,
                           taux_panne=taux_panne,
                           couleur_panne=couleur_panne,
                           energy_data=energy_data_formatted) # <--- CRUCIAL

@auth_bp.get("/performance")
@login_required
def performance_page():
    return render_template("performance.html", user=session["user"])

@auth_bp.get("/robotino")
@login_required
def robotino_page():
    """Page Robotino : Batterie / cycles / disponibilité (à partir d'un CSV)."""

    # Chemin attendu : app/static/data/robotino_data.csv
    csv_path = os.path.join(os.path.dirname(__file__), "static", "data", "robotino_data.csv")

    time_series = []
    battery_pct_series = []
    autonomy_hours_series = []
    battery_low_series = []
    vx_series = []
    vy_series = []
    ext_power_series = []

    kpi_current = {
        "battery_pct": None,
        "autonomy_hours": None,
        "battery_low": False,
        "availability_pct": None,
    }

    cycle_points = []  # {label, total_min, charge_min, travel_min}

    def _parse_ts(s: str):
        try:
            return datetime.fromisoformat(s)
        except Exception:
            return None

    def _to_float(v, default=None):
        try:
            if v in (None, ""):
                return default
            return float(v)
        except Exception:
            return default

    def _to_bool(v) -> bool:
        if isinstance(v, bool):
            return v
        if v is None:
            return False
        s = str(v).strip().lower()
        return s in ("true", "1", "yes")

    if os.path.exists(csv_path):
        with open(csv_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                ts = _parse_ts(row.get("timestamp", ""))
                if not ts:
                    continue

                # Batterie : moyenne des capacities >= 0 (les -2 = “non dispo”)
                caps = []
                for i in range(8):
                    c = _to_float(row.get(f"festool_charger_capacities_{i}"), None)
                    if c is not None and c >= 0:
                        caps.append(c)
                battery_pct = sum(caps) / len(caps) if caps else None

                # Batterie faible : flags Festool + power_batteryLow
                battery_low = (
                    _to_bool(row.get("power_batteryLow"))
                    or _to_bool(row.get("festool_charger_batteryLow_0"))
                    or _to_bool(row.get("festool_charger_batteryLow_1"))
                )

                # Charge : robot branché
                ext_power = _to_bool(row.get("power_ext_power"))

                vx = _to_float(row.get("odometry_vx"), 0.0) or 0.0
                vy = _to_float(row.get("odometry_vy"), 0.0) or 0.0

                time_series.append(ts.isoformat())
                battery_pct_series.append(battery_pct)
                battery_low_series.append(battery_low)
                ext_power_series.append(ext_power)
                vx_series.append(vx)
                vy_series.append(vy)

    # Autonomie (h) = (niveau%/100) * autonomie totale
    # => autonomie totale modifiable côté UI (défaut 2h)
    autonomy_full_hours = 2.0
    for bp in battery_pct_series:
        autonomy_hours_series.append(None if bp is None else round((bp / 100.0) * autonomy_full_hours, 3))

    # KPI current (dernière valeur batterie non nulle)
    for i in range(len(time_series) - 1, -1, -1):
        if battery_pct_series[i] is not None:
            kpi_current["battery_pct"] = round(float(battery_pct_series[i]), 1)
            kpi_current["autonomy_hours"] = round(float(autonomy_hours_series[i]), 2)
            kpi_current["battery_low"] = bool(battery_low_series[i])
            break

    # Disponibilité (V2 – proxy) : temps en mouvement / temps total
    if len(time_series) >= 2:
        tss = [datetime.fromisoformat(t) for t in time_series]
        total_s = 0.0
        active_s = 0.0
        speed_threshold = 0.01  # seuil
        for i in range(1, len(tss)):
            dt = (tss[i] - tss[i - 1]).total_seconds()
            if dt <= 0:
                continue
            total_s += dt
            is_active = (abs(vx_series[i]) + abs(vy_series[i])) > speed_threshold
            if is_active:
                active_s += dt
        if total_s > 0:
            kpi_current["availability_pct"] = round((active_s / total_s) * 100.0, 1)

    # Cycles : proxy via power_ext_power (début/fin de charge)
    if len(time_series) >= 2:
        tss = [datetime.fromisoformat(t) for t in time_series]
        sessions = []  # (start_dt, end_dt)
        start_dt = tss[0] if bool(ext_power_series[0]) else None

        for i in range(1, len(tss)):
            prev = bool(ext_power_series[i - 1])
            cur = bool(ext_power_series[i])
            if (not prev) and cur:
                start_dt = tss[i]
            if prev and (not cur) and start_dt:
                sessions.append((start_dt, tss[i]))
                start_dt = None

        for idx, (s_start, s_end) in enumerate(sessions[:200]):
            charge_min = (s_end - s_start).total_seconds() / 60.0
            travel_min = None
            total_min = None
            if idx + 1 < len(sessions):
                next_start = sessions[idx + 1][0]
                travel_min = (next_start - s_end).total_seconds() / 60.0
                total_min = (next_start - s_start).total_seconds() / 60.0

            cycle_points.append({
                "label": f"Cycle {idx + 1}",
                "charge_min": round(charge_min, 1),
                "travel_min": round(travel_min, 1) if travel_min is not None else None,
                "total_min": round(total_min, 1) if total_min is not None else None,
            })

    return render_template(
        "robotino.html",
        user=session["user"],
        kpi=kpi_current,
        robotino_ts=time_series,
        battery_pct=battery_pct_series,
        autonomy_h=autonomy_hours_series,
        battery_low=battery_low_series,
        ext_power=ext_power_series,
        cycles=cycle_points,
        autonomy_full_hours=autonomy_full_hours,
    )