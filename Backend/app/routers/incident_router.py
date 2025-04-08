# app/routers/incident_router.py
import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from ..db.database import SessionLocal
from ..db import models, schemas
from ..services.auth_service import get_current_user

router = APIRouter(prefix="/incidents", tags=["Incidents"])

# Ensure uploads directory exists
os.makedirs("uploads", exist_ok=True)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.Incident)
async def create_incident(
    title: str = Form(...),
    description: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    media_file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create a new incident with media attachment"""
    try:
        # Create incident object
        incident = models.Incident(
            user_id=current_user.id,
            title=title,
            description=description,
            latitude=latitude,
            longitude=longitude,
            status="submitted"  # Initial status
        )
        
        # Handle image upload if provided
        if media_file and media_file.filename:
            try:
                file_extension = os.path.splitext(media_file.filename)[1]
                filename = f"{uuid.uuid4()}{file_extension}"
                file_path = os.path.join("uploads", filename)
                
                # Make sure uploads directory exists
                os.makedirs("uploads", exist_ok=True)
                
                with open(file_path, "wb") as buffer:
                    buffer.write(await media_file.read())
                
                incident.media_url = file_path
            except Exception as e:
                # Log error but continue with creating incident
                print(f"Error saving file: {str(e)}")
        
        db.add(incident)
        db.commit()
        db.refresh(incident)
        return incident
    except Exception as e:
        # Ensure we return a proper JSON response
        print(f"Error creating incident: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating incident: {str(e)}"
        )

@router.post("/multiple", response_model=schemas.Incident)
async def create_incident_with_multiple_files(
    title: str = Form(...),
    description: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    files: List[UploadFile] = File([]),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create a new incident with multiple file attachments"""
    
    # Create incident object
    incident = models.Incident(
        user_id=current_user.id,
        title=title,
        description=description,
        latitude=latitude,
        longitude=longitude,
        status="submitted"  # Initial status
    )
    
    # Save first image as the main media_url
    if files and len(files) > 0:
        file_extension = os.path.splitext(files[0].filename)[1]
        filename = f"{uuid.uuid4()}{file_extension}"
        file_path = os.path.join("uploads", filename)
        
        with open(file_path, "wb") as buffer:
            buffer.write(await files[0].read())
        
        incident.media_url = file_path
        
        # Add additional files to additional_media field
        additional_media = []
        for i in range(1, len(files)):
            file = files[i]
            file_extension = os.path.splitext(file.filename)[1]
            filename = f"{uuid.uuid4()}{file_extension}"
            file_path = os.path.join("uploads", filename)
            
            with open(file_path, "wb") as buffer:
                buffer.write(await file.read())
            
            additional_media.append(file_path)
        
        incident.additional_media = additional_media
    
    db.add(incident)
    db.commit()
    db.refresh(incident)
    return incident

@router.post("/livestream", response_model=schemas.Incident)
async def create_livestream_incident(
    title: str = Form(...),
    description: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    livestream_url: str = Form(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create a new incident with livestream URL"""
    
    incident = models.Incident(
        user_id=current_user.id,
        title=title,
        description=description,
        latitude=latitude,
        longitude=longitude,
        livestream_url=livestream_url,
        status="submitted"
    )
    
    db.add(incident)
    db.commit()
    db.refresh(incident)
    return incident

@router.get("/media/{incident_id}")
def get_incident_media(incident_id: int, db: Session = Depends(get_db)):
    """Get media file for an incident"""
    incident = db.query(models.Incident).filter(models.Incident.id == incident_id).first()
    if not incident or not incident.media_url:
        raise HTTPException(status_code=404, detail="Media not found")
    
    return FileResponse(incident.media_url)

@router.get("/video/{incident_id}")
def get_incident_video(incident_id: int, db: Session = Depends(get_db)):
    """Get video file for an incident"""
    incident = db.query(models.Incident).filter(models.Incident.id == incident_id).first()
    if not incident or not incident.video_url:
        raise HTTPException(status_code=404, detail="Video not found")
    
    return FileResponse(incident.video_url)

@router.get("/additional-media/{incident_id}/{file_index}")
def get_additional_media(incident_id: int, file_index: int, db: Session = Depends(get_db)):
    """Get additional media file for an incident by index"""
    incident = db.query(models.Incident).filter(models.Incident.id == incident_id).first()
    
    if not incident or not incident.additional_media or len(incident.additional_media) <= file_index:
        raise HTTPException(status_code=404, detail="Media not found")
    
    return FileResponse(incident.additional_media[file_index])

@router.get("/user", response_model=List[schemas.Incident])
async def get_user_incidents(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all incidents for the current user"""
    incidents = db.query(models.Incident).filter(
        models.Incident.user_id == current_user.id
    ).order_by(models.Incident.created_at.desc()).all()
    
    return incidents