from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from .config import Config

# L'instance unique de la base de données
db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # On lie db à l'application
    db.init_app(app)

    # On importe le Blueprint APRÈS l'initialisation de db
    from .auth import auth_bp
    app.register_blueprint(auth_bp)

    return app