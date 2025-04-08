# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os
from .routers import auth_router, incident_router, admin_router
from .db.database import Base, engine
from .db import models

# Ensure necessary directories exist
os.makedirs("uploads", exist_ok=True)
os.makedirs("admin", exist_ok=True)

def create_app():
    # Create database tables
    Base.metadata.create_all(bind=engine)
    
    # In your main.py
    app = FastAPI(
        title="Incident Reporting API",
        description="API for incident reporting and management",
        version="1.0.0",
        docs_url="/docs",  # Explicitly set the docs URL
        redoc_url="/redoc"  # Explicitly set the redoc URL
    )
        
    # Configure CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # In production, restrict to specific origins
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Include routers
    app.include_router(auth_router.router)
    app.include_router(incident_router.router)
    app.include_router(admin_router.router)
    
    # Mount static directories
    app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
    app.mount("/admin-static", StaticFiles(directory="admin"), name="admin-static")
    
    # Root endpoint
    @app.get("/")
    def root():
        return {
            "message": "Welcome to Incident Reporting API",
            "documentation": "/docs",
            "admin_panel": "/admin"
        }
    
    @app.get("/test")
    def test_endpoint():
        return {"status": "working"}
    # Admin panel endpoint
    @app.get("/admin", include_in_schema=False)
    async def admin_interface():
        return FileResponse("admin/index.html")
    
    return app

app = create_app()