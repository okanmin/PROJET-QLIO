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
    return render_template("robotino.html", user=session["user"])