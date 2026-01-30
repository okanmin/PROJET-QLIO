import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # IMPORTANT: à personnaliser via variable d'env en prod
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-change-me-please-very-secret")
    WTF_CSRF_TIME_LIMIT = None  # évite les expirations pénibles en dev
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Lax"
    # SESSION_COOKIE_SECURE = True  # à activer si HTTPS
    SQLALCHEMY_DATABASE_URI = f"mysql+pymysql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}/{os.getenv('DB_NAME')}"