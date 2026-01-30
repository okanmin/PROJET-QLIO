import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # IMPORTANT: à personnaliser via variable d'env en prod
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-change-me-please-very-secret")
    WTF_CSRF_TIME_LIMIT = None  # évite les expirations pénibles en dev
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Lax"
    SQLALCHEMY_DATABASE_URI = "mysql+pymysql://example_user:example_password@mariadb/MES4_Analysis"
    SQLALCHEMY_TRACK_MODIFICATIONS = False