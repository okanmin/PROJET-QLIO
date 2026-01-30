from app import create_app

app = create_app()

if __name__ == "__main__":
    # host=0.0.0.0 si tu veux accéder depuis un autre poste sur le réseau
    app.run(host="0.0.0.0", port=5000, debug=False)
