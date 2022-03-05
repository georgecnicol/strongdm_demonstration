from flask import render_template, Blueprint

src = Blueprint('src', __name__, template_folder = 'templates/src')  # register this in init


@src.route('/', methods = ['GET'])
def index():
    return render_template('index.html')
