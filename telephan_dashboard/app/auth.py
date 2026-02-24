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

@auth_bp.get("/home")
@login_required
def home():
    """Page d'accueil : Présentation du projet"""
    return render_template("home.html", user=session["user"])

@auth_bp.get("/qualite")
@login_required
def qualite_page():
    """Page Qualité : Calculs effectués en Python pour un affichage HTML pur"""
    success_kpi = {"taux": 0, "nb": 0, "total": 0}
    pareto_data_formatted = []
    
    try:
        # Récupération des données classées de la vue SQL
        query = text("""
            SELECT Categorie, Quantite, Pourcentage_Courbe, Total_General 
            FROM MES4_Analysis.V_Pareto_Global
            ORDER BY Quantite DESC
        """)
        results = db.session.execute(query).fetchall()
        
        if results:
            # 1. Calcul du KPI global pour les cartes (On cherche la ligne OK/Conforme)
            for row in results:
                # SÉCURISATION : Si la catégorie est NULL, on la remplace par du texte
                categorie = str(row[0] or "Erreur non référencée")
                # SÉCURISATION : Forcer en entiers pour éviter les bugs "Decimal"
                quantite = int(row[1] or 0)
                total_gen = int(row[3] or 0)
                
                if "OK" in categorie.upper() or "CONFORME" in categorie.upper():
                    success_kpi = {
                        "nb": quantite,
                        "total": total_gen,
                        "taux": float(round((quantite / total_gen) * 100, 1)) if total_gen > 0 else 0.0
                    }
                    break
            
            # 2. Formatage des données pour le rendu HTML
            cumul = 0.0
            for row in results:
                # SÉCURISATION DES TYPES
                categorie = str(row[0] or "Erreur non référencée")
                quantite = int(row[1] or 0)
                total_gen = int(row[3] or 0)
                
                # Calcul de la proportion exacte par rapport au total (en float pour JS)
                pourcentage = float((quantite / total_gen * 100)) if total_gen > 0 else 0.0
                
                cumul += pourcentage
                if cumul > 100.0:
                    cumul = 100.0 # Éviter les dépassements (100.01% etc.) dus aux arrondis
                    
                is_ok = "OK" in categorie.upper() or "CONFORME" in categorie.upper()
                
                # Création d'un dictionnaire prêt à être lu par Jinja2 et Chart.js
                pareto_data_formatted.append({
                    "label": categorie,
                    "qty": quantite,
                    "pct": float(round(pourcentage, 1)),
                    "cumul": float(round(cumul, 1)),
                    "is_ok": is_ok
                })

    except Exception as e:
        # Affichera l'erreur précise dans les logs du terminal (Docker)
        print(f"!!! ERREUR SQL QUALITÉ !!! : {e}")

    return render_template("qualite.html", 
                           user=session["user"], 
                           success_kpi=success_kpi, 
                           pareto_data=pareto_data_formatted)

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