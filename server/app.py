from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO, emit, join_room, leave_room
import json
import os
from datetime import datetime

app = Flask(__name__)
app.config['SECRET_KEY'] = 'chattrace_secret_key_2026'
socketio = SocketIO(app, cors_allowed_origins="*")

# Load configuration with fallback values
try:
    config_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'config.json')
    with open(config_path, 'r') as f:
        config = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    # Fallback configuration
    config = {
        'port': 5000,
        'log_file': os.path.join(os.path.dirname(__file__), 'logs', 'chat.log'),
        'cloudflared_path': os.path.join(os.path.dirname(os.path.dirname(__file__)), 'bin', 'cloudflared')
    }
    # Create logs directory if it doesn't exist
    os.makedirs(os.path.dirname(config['log_file']), exist_ok=True)

LOG_FILE = config['log_file']

def log_event(event_type, data):
    """Log events to file"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f"[{timestamp}] {event_type}: {data}\n"
    
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(log_entry)

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('connect')
def handle_connect():
    print(f'Client connected: {request.sid}')
    log_event('CONNECT', f'Session {request.sid} connected')

@socketio.on('join')
def handle_join(data):
    username = data.get('username', 'Anonymous')
    room = 'main_chat'
    join_room(room)
    
    log_event('JOIN', f'User {username} joined from session {request.sid}')
    socketio.emit('user_joined', {'username': username}, room=room)

@socketio.on('message')
def handle_message(data):
    username = data.get('username', 'Anonymous')
    message = data.get('message', '')
    room = 'main_chat'
    
    # Only log the message if you want to track them in the log file
    # For clean terminal output, we don't log messages to the terminal
    log_event('MESSAGE', f'{username}: {message}')
    socketio.emit('new_message', {
        'username': username,
        'message': message,
        'timestamp': datetime.now().strftime('%H:%M:%S')
    }, room=room)

@socketio.on('disconnect')
def handle_disconnect():
    log_event('DISCONNECT', f'Session {request.sid} disconnected')
    print(f'Client disconnected: {request.sid}')

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=config['port'], debug=False, allow_unsafe_werkzeug=True)
