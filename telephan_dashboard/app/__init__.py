from flask import Flask, render_template
from .config import Config
from .auth import auth_bp

def create_app():
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_object(Config)

    app.register_blueprint(auth_bp)

    @app.errorhandler(404)
    def not_found(_e):
        return render_template("404.html"), 404

    return app
