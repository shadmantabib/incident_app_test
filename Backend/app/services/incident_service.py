# app/services/incident_service.py
import os
import uuid
from fastapi import UploadFile
from ..db import models, schemas
from sqlalchemy.orm import Session

UPLOAD_DIR = "uploads"

# In app/services/incident_service.py
def save_incident(db: Session, user_id: int, incident_data: schemas.IncidentCreate, file_path: str = None):
    new_incident = models.Incident(
        user_id=user_id,
        title=incident_data.title,
        description=incident_data.description,
        latitude=incident_data.latitude,
        longitude=incident_data.longitude,
        media_url=file_path or ""  # Change this from media_path to media_url
    )
    db.add(new_incident)
    db.commit()
    db.refresh(new_incident)
    return new_incident

def save_file_to_local_disk(file: UploadFile) -> str:
    # Generate a unique filename
    extension = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4().hex}{extension}"
    file_location = os.path.join(UPLOAD_DIR, unique_filename)

    with open(file_location, "wb") as f:
        f.write(file.file.read())  # read and write the file

    return file_location
