import json
import os
import getpass
import bcrypt

USERS_FILE = os.path.join("instance", "users.json")

def load_users():
    if not os.path.exists(USERS_FILE):
        return {}
    with open(USERS_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def save_users(users):
    os.makedirs(os.path.dirname(USERS_FILE), exist_ok=True)
    with open(USERS_FILE, "w", encoding="utf-8") as f:
        json.dump(users, f, indent=2, ensure_ascii=False)

def main():
    users = load_users()

    username = input("Identifiant: ").strip()
    if not username:
        print("Identifiant vide.")
        return

    if username in users:
        print("Cet utilisateur existe déjà.")
        return

    password = getpass.getpass("Mot de passe: ").strip()
    if len(password) < 8:
        print("Mot de passe trop court (min 8).")
        return

    role = (input("Rôle (admin/membre/lecteur) [lecteur]: ").strip() or "lecteur").lower()
    if role not in {"admin", "membre", "lecteur"}:
        print("Rôle invalide. Choisis: admin, membre ou lecteur.")
        return

    pw_hash = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
    users[username] = {"password_hash": pw_hash, "role": role}

    save_users(users)
    print(f"Utilisateur '{username}' créé ✅")

if __name__ == "__main__":
    main()
