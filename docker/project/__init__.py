from flask import Flask


def make_app():
    app = Flask(__name__)

    # register blueprints
    from project.src.view import src
    app.register_blueprint(src)  # no prefix because this is views off the src

    return app
