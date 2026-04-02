from flask import Flask, render_template, session
from flask_sqlalchemy import SQLAlchemy
from .config import Config

# Instance unique SQLAlchemy conservée pour l'architecture Docker d'origine
db = SQLAlchemy()


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)

    from .auth import auth_bp
    app.register_blueprint(auth_bp)

    @app.errorhandler(404)
    def page_not_found(error):
        user = session.get("user")
        return render_template("404.html", user=user), 404

    return app
