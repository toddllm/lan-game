#!/usr/bin/env python3
import bcrypt
import getpass
import json
import os
from datetime import datetime

def set_password():
    # Prompt for password without showing input
    password = getpass.getpass("Enter the new password: ")
    confirm = getpass.getpass("Confirm password: ")
    
    if password != confirm:
        print("Passwords don't match!")
        return
    
    # Convert the password to bytes and hash it
    password_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password_bytes, salt)
    
    # Create credentials object
    credentials = {
        'password_hash': hashed.decode('utf-8'),
        'created_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    }
    
    # Save to file
    with open('game_credentials.json', 'w') as f:
        json.dump(credentials, f, indent=2)
    
    print("\nPassword updated successfully!")
    print(f"Credentials saved to: {os.path.abspath('game_credentials.json')}")
    print(f"\nYou can now share this password with your friends: {password}")

if __name__ == "__main__":
    set_password()
