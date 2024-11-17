# src/server/server.py
from flask import Flask, render_template, request, session, redirect, url_for
from flask_socketio import SocketIO, emit, disconnect, join_room, leave_room
from functools import wraps
import bcrypt
import json
import os
from datetime import datetime, UTC
from game_db import GameDB

# Get the absolute path to the templates directory
template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'templates'))
static_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'static'))

app = Flask(__name__, 
           template_folder=template_dir,
           static_folder=static_dir)
app.config['SECRET_KEY'] = 'replace_with_your_secure_random_string'
socketio = SocketIO(app)

print(f"Template directory: {template_dir}")
print(f"Current working directory: {os.getcwd()}")
print(f"Template folder from Flask: {app.template_folder}")

db = GameDB()

def load_password_hash():
    try:
        with open('game_credentials.json', 'r') as f:
            credentials = json.load(f)
            return credentials['password_hash'].encode('utf-8')
    except FileNotFoundError:
        print("ERROR: game_credentials.json not found!")
        print("Please run 'python scripts/create-pw.py' to create a password first.")
        os._exit(1)
    except Exception as e:
        print(f"ERROR loading credentials: {e}")
        os._exit(1)

# Login required decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get('authenticated'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# Socket authentication decorator
def authenticated_only(f):
    @wraps(f)
    def wrapped(*args, **kwargs):
        if not session.get('authenticated'):
            disconnect()
            return
        return f(*args, **kwargs)
    return wrapped

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        password = request.form.get('password').encode('utf-8')
        password_hash = load_password_hash()
        if bcrypt.checkpw(password, password_hash):
            session['authenticated'] = True
            return redirect(url_for('game_list'))
        return render_template('login.html', error="Invalid password")
    return render_template('login.html')

@app.route('/')
@login_required
def game_list():
    games = db.list_games()
    return render_template('game_list.html', games=games)

@app.route('/game/create', methods=['POST'])
@login_required
def create_game():
    name = request.form.get('name')
    try:
        game_id = db.create_game(name)
        return redirect(url_for('game', game_name=name))
    except ValueError as e:
        return render_template('game_list.html', error=str(e), games=db.list_games())

@app.route('/game/<game_name>')
@login_required
def game(game_name):
    game_data = db.get_game(name=game_name)
    if not game_data:
        return redirect(url_for('game_list'))
    return render_template('index.html', game=game_data)

@socketio.on('join')
@authenticated_only
def on_join(data):
    game_name = data.get('game_name')
    print(f"Joining game: {game_name}")  # Debug print
    game_data = db.get_game(name=game_name)
    if game_data:
        join_room(game_data['id'])
        shapes = json.loads(game_data['shapes'])
        emit('all_shapes', shapes)
        print(f"Emitted {len(shapes)} shapes")  # Debug print

@socketio.on('place_shape')
@authenticated_only
def handle_shape(data):
    game_id = data.get('game_id')
    if not game_id:
        return
    
    game_data = db.get_game(game_id=game_id)
    if not game_data:
        return
    
    shapes = json.loads(game_data['shapes'])
    new_shape = {
        'type': data['type'],
        'x': data['x'],
        'y': data['y'],
        'timestamp': datetime.now(UTC).isoformat()
    }
    shapes.append(new_shape)
    
    db.update_shapes(game_id, shapes)
    emit('shape_placed', new_shape, room=game_id)
    print(f"Shape placed in game {game_id}: {new_shape}")  # Debug print

@socketio.on('get_shapes')
@authenticated_only
def handle_get_shapes(data):
    game_id = data.get('game_id')
    if game_id:
        game_data = db.get_game(game_id=game_id)
        if game_data:
            shapes = json.loads(game_data['shapes'])
            emit('all_shapes', shapes)

if __name__ == '__main__':
    load_password_hash()
    socketio.run(app, host='0.0.0.0', port=5001, debug=True)