# src/server/game_db.py
import sqlite3
from datetime import datetime
import uuid
import json
from contextlib import contextmanager

class GameDB:
    def __init__(self, db_path='games.db'):
        self.db_path = db_path
        self.init_db()
    
    @contextmanager
    def get_db(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        finally:
            conn.close()
    
    def init_db(self):
        with self.get_db() as conn:
            conn.execute('''
                CREATE TABLE IF NOT EXISTS games (
                    id TEXT PRIMARY KEY,
                    name TEXT UNIQUE NOT NULL,
                    created_at TIMESTAMP NOT NULL,
                    last_modified TIMESTAMP NOT NULL,
                    shapes TEXT,
                    active BOOLEAN DEFAULT 1
                )
            ''')
            conn.execute('CREATE INDEX IF NOT EXISTS idx_game_name ON games(name)')
            conn.commit()
    
    def create_game(self, name):
        """Create a new game with a unique name"""
        game_id = str(uuid.uuid4())
        now = datetime.utcnow()
        
        with self.get_db() as conn:
            try:
                conn.execute('''
                    INSERT INTO games (id, name, created_at, last_modified, shapes)
                    VALUES (?, ?, ?, ?, ?)
                ''', (game_id, name, now, now, '[]'))
                conn.commit()
                return game_id
            except sqlite3.IntegrityError:
                raise ValueError(f"Game name '{name}' already exists")
    
    def get_game(self, name=None, game_id=None):
        """Get game by name or ID"""
        with self.get_db() as conn:
            if name:
                row = conn.execute('SELECT * FROM games WHERE name = ? AND active = 1', (name,)).fetchone()
            elif game_id:
                row = conn.execute('SELECT * FROM games WHERE id = ? AND active = 1', (game_id,)).fetchone()
            else:
                raise ValueError("Must provide either name or game_id")
                
            if row:
                return dict(row)
            return None
    
    def update_shapes(self, game_id, shapes):
        """Update shapes for a game"""
        with self.get_db() as conn:
            conn.execute('''
                UPDATE games 
                SET shapes = ?, last_modified = ?
                WHERE id = ? AND active = 1
            ''', (json.dumps(shapes), datetime.utcnow(), game_id))
            conn.commit()
    
    def list_games(self):
        """List all active games"""
        with self.get_db() as conn:
            rows = conn.execute('''
                SELECT id, name, created_at, last_modified 
                FROM games 
                WHERE active = 1
                ORDER BY last_modified DESC
            ''').fetchall()
            return [dict(row) for row in rows]
    
    def delete_game(self, game_id):
        """Soft delete a game"""
        with self.get_db() as conn:
            conn.execute('UPDATE games SET active = 0 WHERE id = ?', (game_id,))
            conn.commit()