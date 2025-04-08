from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import csv
import io
from datetime import datetime, timedelta
from ..db.database import SessionLocal
from ..db import models, schemas
from ..core.security import verify_password, create_access_token, hash_password
from datetime import timedelta
from sqlalchemy import func, desc
from ..services.auth_service import get_admin_user

router = APIRouter(prefix="/admin", tags=["Admin"])

# JWT token settings
ACCESS_TOKEN_EXPIRE_MINUTES = 60

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Admin login
@router.post("/login", response_model=dict)
def admin_login(login_data: schemas.AdminLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter_by(email=login_data.email).first()
    
    if not user or not verify_password(login_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User does not have admin privileges",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email, "admin": True, "admin_level": user.admin_level}, 
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

# Get all incidents (with admin access check)
@router.get("/incidents", response_model=List[schemas.Incident])
def get_all_incidents(
    status: Optional[str] = None,
    db: Session = Depends(get_db), 
    current_admin: models.User = Depends(get_admin_user(1))
):
    query = db.query(models.Incident)
    
    if status and status != "all":
        query = query.filter(models.Incident.status == status)
    
    incidents = query.order_by(desc(models.Incident.created_at)).all()
    return incidents

# @router.get("/incidents", response_model=List[schemas.Incident])
# def get_all_incidents(
#     status: Optional[str] = None,
#     db: Session = Depends(get_db)
# ):
#     query = db.query(models.Incident)
    
#     if status and status != "all":
#         query = query.filter(models.Incident.status == status)
    
#     incidents = query.order_by(desc(models.Incident.created_at)).all()
#     return incidents


# Get specific incident
@router.get("/incidents/{incident_id}", response_model=schemas.Incident)
def get_incident(
    incident_id: int, 
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(1))
):
    incident = db.query(models.Incident).filter(models.Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    return incident

# Update incident status and remarks
@router.patch("/incidents/{incident_id}", response_model=schemas.Incident)
def update_incident(
    incident_id: int, 
    incident_update: schemas.IncidentUpdate, 
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(1))
):
    incident = db.query(models.Incident).filter(models.Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    if incident_update.status:
        # Validate status value
        valid_statuses = ["submitted", "under_process", "resolved", "rejected"]
        if incident_update.status not in valid_statuses:
            raise HTTPException(status_code=400, detail="Invalid status value")
        incident.status = incident_update.status
    
    if incident_update.admin_remarks is not None:
        incident.admin_remarks = incident_update.admin_remarks
    
    db.commit()
    db.refresh(incident)
    return incident

# Get incident file
@router.get("/incidents/file/{incident_id}")
def get_incident_file(
    incident_id: int, 
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(1))
):
    incident = db.query(models.Incident).filter(models.Incident.id == incident_id).first()
    if not incident or not incident.media_url:
        raise HTTPException(status_code=404, detail="File not found")
    
    file_path = incident.media_url
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found on server")
    
    return FileResponse(file_path)

# Get incident video
@router.get("/incidents/video/{incident_id}")
def get_incident_video(
    incident_id: int, 
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(1))
):
    incident = db.query(models.Incident).filter(models.Incident.id == incident_id).first()
    if not incident or not incident.video_url:
        raise HTTPException(status_code=404, detail="Video not found")
    
    file_path = incident.video_url
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Video not found on server")
    
    return FileResponse(file_path)

# Get all users (admin level access)
@router.get("/users", response_model=List[schemas.UserInfo])
def get_all_users(
    db: Session = Depends(get_db), 
    current_admin: models.User = Depends(get_admin_user(2))
):
    users = db.query(models.User).all()
    return users

# Get specific user
@router.get("/users/{user_id}", response_model=schemas.UserInfo)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(2))
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# Create new user (admin only)
@router.post("/users", response_model=schemas.UserInfo)
def create_user(
    user_data: schemas.UserCreate,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(2))
):
    # Check if user with this email already exists
    existing_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Hash the password
    hashed_password = hash_password(user_data.password)
    
    # Create new user
    new_user = models.User(
        email=user_data.email,
        password=hashed_password,
        is_admin=user_data.is_admin,
        admin_level=user_data.admin_level
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

# Update user (admin only)
@router.put("/users/{user_id}", response_model=schemas.UserInfo)
def update_user(
    user_id: int,
    user_data: schemas.UserCreate,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(2))
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update email if it's not already used by another user
    if user_data.email != user.email:
        existing_user = db.query(models.User).filter(models.User.email == user_data.email).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        user.email = user_data.email
    
    # Update password if provided
    if user_data.password:
        user.password = hash_password(user_data.password)
    
    # Update admin status
    user.is_admin = user_data.is_admin
    user.admin_level = user_data.admin_level
    
    db.commit()
    db.refresh(user)
    return user

# Delete user (admin only)
@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(2))
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    return {"status": "success"}

@router.get("/stats", response_model=schemas.AdminStats)
def get_admin_stats(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(1))
):
    """Get statistics for the admin dashboard."""
    
    # Get total incidents count
    total_incidents = db.query(func.count(models.Incident.id)).scalar()
    
    # Get counts by status
    submitted_incidents = db.query(func.count(models.Incident.id)).filter(
        models.Incident.status.in_(["submitted", "pending"])
    ).scalar()
    
    under_process_incidents = db.query(func.count(models.Incident.id)).filter(
        models.Incident.status.in_(["under_process", "in_progress"])
    ).scalar()
    
    resolved_incidents = db.query(func.count(models.Incident.id)).filter(
        models.Incident.status == "resolved"
    ).scalar()
    
    rejected_incidents = db.query(func.count(models.Incident.id)).filter(
        models.Incident.status == "rejected"
    ).scalar()
    
    # Get total users count
    total_users = db.query(func.count(models.User.id)).scalar()
    
    # Get count of admin users
    admin_users = db.query(func.count(models.User.id)).filter(
        models.User.is_admin == True
    ).scalar()
    
    # Get recent incidents (last 5)
    try:
        # Try with all fields first (including the new ones)
        recent_incidents = db.query(models.Incident).order_by(desc(models.Incident.created_at)).limit(5).all()
    except Exception as e:
        # If that fails, use a more restricted query that only selects specific columns
        recent_incidents = db.query(
            models.Incident.id,
            models.Incident.user_id,
            models.Incident.title,
            models.Incident.description,
            models.Incident.latitude,
            models.Incident.longitude,
            models.Incident.media_url,
            models.Incident.status,
            models.Incident.created_at
        ).order_by(desc(models.Incident.created_at)).limit(5).all()
    
    return {
        "total_incidents": total_incidents,
        "pending_incidents": submitted_incidents,  # For backward compatibility
        "in_progress_incidents": under_process_incidents,  # For backward compatibility
        "resolved_incidents": resolved_incidents,
        "rejected_incidents": rejected_incidents,
        "total_users": total_users,
        "admin_users": admin_users,
        "recent_incidents": recent_incidents,
        "incidents_last_week": total_incidents,  # Simplified for now
        "users_last_month": total_users  # Simplified for now
    }

# Generate report
@router.get("/reports/incidents", response_model=schemas.ReportData)
def generate_incident_report(
    status: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(1))
):
    """Generate a report of incidents"""
    
    query = db.query(models.Incident)
    
    # Apply date filters if provided
    if from_date:
        from_datetime = datetime.strptime(from_date, "%Y-%m-%d")
        query = query.filter(models.Incident.created_at >= from_datetime)
    
    if to_date:
        to_datetime = datetime.strptime(to_date, "%Y-%m-%d")
        to_datetime = to_datetime + timedelta(days=1)  # Include the entire day
        query = query.filter(models.Incident.created_at < to_datetime)
    
    # Apply status filter if provided
    if status:
        query = query.filter(models.Incident.status == status)
    
    # Get incidents
    incidents = query.order_by(desc(models.Incident.created_at)).all()
    
    # Get counts by status
    status_counts = {
        "submitted": 0,
        "under_process": 0,
        "resolved": 0,
        "rejected": 0
    }
    
    for incident in incidents:
        if incident.status in status_counts:
            status_counts[incident.status] += 1
    
    return {
        "total_incidents": len(incidents),
        "by_status": status_counts,
        "incidents": incidents
    }

# Export incidents to CSV
@router.get("/reports/incidents/csv")
def export_incidents_to_csv(
    status: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(get_admin_user(1))
):
    """Export incidents to CSV file"""
    
    # Get incidents with filters
    query = db.query(models.Incident)
    
    if status:
        query = query.filter(models.Incident.status == status)
    
    if from_date:
        from_datetime = datetime.strptime(from_date, "%Y-%m-%d")
        query = query.filter(models.Incident.created_at >= from_datetime)
    
    if to_date:
        to_datetime = datetime.strptime(to_date, "%Y-%m-%d")
        to_datetime = to_datetime + timedelta(days=1)
        query = query.filter(models.Incident.created_at < to_datetime)
    
    incidents = query.order_by(desc(models.Incident.created_at)).all()
    
    # Create CSV file in memory
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write header
    writer.writerow([
        "ID", "User ID", "Title", "Description", "Latitude", "Longitude", 
        "Status", "Admin Remarks", "Created At", "Updated At"
    ])
    
    # Write data
    for incident in incidents:
        writer.writerow([
            incident.id,
            incident.user_id,
            incident.title,
            incident.description,
            incident.latitude,
            incident.longitude,
            incident.status,
            incident.admin_remarks,
            incident.created_at,
            incident.updated_at
        ])
    
    # Prepare response
    output.seek(0)
    
    # Generate filename with timestamp
    filename = f"incidents_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    
    # Return CSV as a downloadable file
    return FileResponse(
        path=output.getvalue(),
        media_type="text/csv",
        filename=filename
    )