#!/usr/bin/env python3
import sqlite3
import os

def init_db():
    db_path = "games.db"
    
    # Remove existing database if it exists
    if os.path.exists(db_path):
        os.remove(db_path)
    
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # Create games table
    c.execute("""
        CREATE TABLE IF NOT EXISTS games (
            id TEXT PRIMARY KEY,
            name TEXT UNIQUE NOT NULL,
            created_at TIMESTAMP NOT NULL,
            last_modified TIMESTAMP NOT NULL,
            shapes TEXT,
            active BOOLEAN DEFAULT 1
        )
    """)
    
    # Create index
    c.execute("CREATE INDEX IF NOT EXISTS idx_game_name ON games(name)")
    
    conn.commit()
    conn.close()
    
    print("Database initialized successfully")

if __name__ == "__main__":
    init_db()
