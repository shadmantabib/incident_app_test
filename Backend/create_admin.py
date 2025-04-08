from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import bcrypt
import sys
import os

# Add the parent directory to sys.path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import your models directly
from app.db.database import Base, engine, SessionLocal
from app.db.models import User

def create_admin_user():
    db = SessionLocal()
    try:
        # Check if admin already exists
        existing_admin = db.query(User).filter_by(email="admin1230@example.com").first()
        if existing_admin:
            print("Admin user already exists!")
            return
        
        # Hash password directly with bcrypt
        hashed_password = bcrypt.hashpw("admin123".encode('utf-8'), bcrypt.gensalt())
        
        # Create new admin user
        admin_user = User(
            email="admin@example.com",
            password=hashed_password.decode('utf-8'),  # Convert bytes to string
            is_admin=True,
            admin_level=2
        )
        db.add(admin_user)
        db.commit()
        print("Admin user created successfully!")
    except Exception as e:
        print(f"Error creating admin user: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    create_admin_user()