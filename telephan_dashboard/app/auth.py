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

def role_required(*allowed_roles):
    def decorator(view):
        @wraps(view)
        def wrapped(*args, **kwargs):
            if not session.get("user"):
                return redirect(url_for("auth.login", next=request.path))
            role = session["user"].get("role", "lecteur")
            if role not in allowed_roles:
                flash("Accès refusé : droits insuffisants.", "error")
                return redirect(url_for("auth.home"))
            return view(*args, **kwargs)
        return wrapped
    return decorator

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
            next_url = request.args.get("next") or url_for("auth.home")
            return redirect(next_url)
        flash("Identifiants invalides.", "error")
    return render_template("login.html", form=form)

@auth_bp.get("/logout")
def logout():
    session.clear()
    return redirect(url_for("auth.login"))

# --- Nouvelles Routes par métier ---

# --- Routes par Services ---

# --- Routes par Services (Filtres opérationnels) ---

@auth_bp.get("/home")
@login_required
def home():
    """Page d'accueil : Présentation du projet"""
    return render_template("home.html", user=session["user"])

@auth_bp.get("/qualite")
@login_required
def qualite_page():
    """Page Qualité : Diagramme de Pareto complet"""
    success_kpi = {"taux": 0, "nb": 0, "total": 0}
    pareto_data = []
    
    try:
        # Récupération de toutes les lignes (OK + KO) classées par quantité décroissante
        query = text("""
            SELECT Categorie, Quantite, Pourcentage_Courbe, Total_General 
            FROM MES4_Analysis.V_Pareto_Global
        """)
        results = db.session.execute(query).fetchall()
        
        if results:
            pareto_data = results
            # Calcul du KPI pour la carte de score
            for row in results:
                if row[0] == 'Opération Conforme (OK)':
                    success_kpi = {
                        "nb": row[1],
                        "total": row[3],
                        "taux": round((row[1] / row[3]) * 100, 1) if row[3] > 0 else 0
                    }
                    break
    except Exception as e:
        print(f"Erreur SQL Qualité : {e}")

    return render_template("qualite.html", 
                           user=session["user"], 
                           success_kpi=success_kpi, 
                           pareto_data=pareto_data)

@auth_bp.get("/performance")
@login_required
def performance_page():
    """Page Performance : Consommation énergétique"""
    energy_data = []
    try:
        query = text("SELECT * FROM MES4_Analysis.v_conso_energetique_reelle LIMIT 10")
        energy_data = db.session.execute(query).fetchall()
    except Exception as e:
        print(f"Erreur SQL Performance : {e}")
    return render_template("performance.html", user=session["user"], energy_data=energy_data)

@auth_bp.get("/robotino")
@login_required
def robotino_page():
    """Page Robotino : Suivi logistique"""
    return render_template("robotino.html", user=session["user"])

@auth_bp.get("/admin")
@login_required
@role_required("admin")
def admin_page():
    return render_template("home.html", user=session["user"], title="Admin", energy_data=[])

@auth_bp.get("/membre")
@login_required
@role_required("admin", "membre")
def membre_page():
    return render_template("home.html", user=session["user"], title="Membre", energy_data=[])
