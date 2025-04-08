# app/db/models.py
from sqlalchemy import JSON, Column, Integer, String, Float, ForeignKey, Text, Boolean, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True)
    password = Column(String(255))
    is_admin = Column(Boolean, default=False)
    admin_level = Column(Integer, default=0)  # 0=user, 1=operator, 2=admin
    created_at = Column(DateTime, default=func.now())

class Incident(Base):
    __tablename__ = 'incidents'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    title = Column(String(255))
    description = Column(Text)
    latitude = Column(Float)
    longitude = Column(Float)
    media_url = Column(String(1024), nullable=True)
    video_url = Column(String(1024), nullable=True)  # For uploaded videos
    livestream_url = Column(String(1024), nullable=True)  # For live capture URLs
    additional_media = Column(JSON, nullable=True)  # For multiple image uploads stored as a JSON array
    status = Column(String(50), default="submitted")  # Values: submitted, under_process, resolved, rejected
    admin_remarks = Column(Text, nullable=True)  # Admin remarks field
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())