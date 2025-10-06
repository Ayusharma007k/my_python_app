from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def home():
    env = os.getenv("APP_ENV", "unknown")
    return f"<h1>Hello from {env.upper()} environment!</h1>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
