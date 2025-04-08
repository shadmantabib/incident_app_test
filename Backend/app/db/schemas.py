# app/db/schemas.py
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class UserCreate(BaseModel):
    email: str
    password: str
    is_admin: bool = False
    admin_level: int = 0
    
class UserLogin(BaseModel):
    email: str
    password: str

class AdminLogin(BaseModel):
    email: str
    password: str

class UserInfo(BaseModel):
    id: int
    email: str
    is_admin: bool
    admin_level: int
    
    class Config:
        from_attributes = True

class IncidentBase(BaseModel):
    title: str
    description: str
    latitude: float
    longitude: float

class IncidentCreate(IncidentBase):
    pass

class Incident(BaseModel):
    id: int
    user_id: int
    title: str
    description: str
    latitude: float
    longitude: float
    media_url: Optional[str] = None
    video_url: Optional[str] = None
    livestream_url: Optional[str] = None
    additional_media: Optional[List[str]] = None
    status: str
    admin_remarks: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class IncidentUpdate(BaseModel):
    status: Optional[str] = None
    admin_remarks: Optional[str] = None

class AdminStats(BaseModel):
    """Schema for admin dashboard statistics."""
    total_incidents: int
    pending_incidents: int  # Will be renamed to submitted_incidents
    in_progress_incidents: int  # Will be renamed to under_process_incidents
    resolved_incidents: int
    rejected_incidents: int
    total_users: int
    admin_users: int
    recent_incidents: List[Incident]
    
    class Config:
        from_attributes = True

class ReportData(BaseModel):
    """Schema for report data"""
    total_incidents: int
    by_status: dict
    incidents: List[Incident]
    
    class Config:
        from_attributes = True