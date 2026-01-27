import json
import os
from functools import wraps
from flask import Blueprint, render_template, redirect, url_for, session, request, flash
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField
from wtforms.validators import DataRequired
import bcrypt

auth_bp = Blueprint("auth", __name__)

USERS_FILE = os.path.join("instance", "users.json")

def _load_users():
    if not os.path.exists(USERS_FILE):
        return {}
    with open(USERS_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def _verify_password(password: str, hashed: str) -> bool:
    # hashed stocké en string -> bytes
    return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))

def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("user"):
            return redirect(url_for("auth.login", next=request.path))
        return view(*args, **kwargs)
    return wrapped

class LoginForm(FlaskForm):
    username = StringField("Identifiant", validators=[DataRequired()])
    password = PasswordField("Mot de passe", validators=[DataRequired()])

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

@auth_bp.get("/home")
@login_required
def home():
    return render_template("home.html", user=session["user"])

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

@auth_bp.get("/admin")
@login_required
@role_required("admin")
def admin_page():
    return render_template("home.html", user=session["user"], title="Admin")

@auth_bp.get("/membre")
@login_required
@role_required("admin", "membre")
def membre_page():
    return render_template("home.html", user=session["user"], title="Membre")
