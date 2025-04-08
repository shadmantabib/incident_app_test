# Incident Reporting System

A comprehensive incident reporting system with user and admin panels, built with FastAPI, SQLAlchemy, and Bootstrap.

## Features

- **User Features**:
  - Submit incidents with details (title, description, location)
  - Upload images and videos as evidence
  - Provide livestream URL for real-time monitoring
  - Track incident status

- **Admin Features**:
  - Admin dashboard with statistics
  - Incident management
  - User management with role-based access (Admin/Operator)
  - Status workflow (Submitted -> Under Process -> Resolved)
  - Admin remarks for incidents
  - Report generation and export

## Installation

### Prerequisites

- Python 3.8+
- MySQL

### Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/incident-reporting.git
   cd incident-reporting
   ```

2. Create a virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate   # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

4. Create a MySQL database:
   ```
   CREATE DATABASE infodb;
   ```

5. Configure environment variables in `.env` file:
   ```
   # Modify database credentials as needed
   DB_USER=root
   DB_PASSWORD=your_password
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_NAME=infodb
   
   # JWT settings - IMPORTANT: Change this in production!
   JWT_SECRET_KEY=your_secure_secret_key_here
   ```

6. Run the application:
   ```
   uvicorn app.main:app --reload
   ```

7. Access the application:
   - API documentation: http://127.0.0.1:8000/docs
   - Admin panel: http://127.0.0.1:8000/admin

## Admin Setup

1. Create an admin user using the API:
   ```
   curl -X POST "http://127.0.0.1:8000/admin/users" \
     -H "Content-Type: application/json" \
     -d '{
       "email": "admin@example.com",
       "password": "securepassword",
       "is_admin": true,
       "admin_level": 2
     }'
   ```

2. Log in to the admin panel using these credentials.

## Directory Structure

```
incident-reporting/
├── app/
│   ├── core/
│   │   ├── __init__.py
│   │   └── security.py
│   ├── db/
│   │   ├── __init__.py
│   │   ├── database.py
│   │   ├── models.py
│   │   └── schemas.py
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── admin_router.py
│   │   ├── auth_router.py
│   │   └── incident_router.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   └── incident_service.py
│   ├── __init__.py
│   └── main.py
├── admin/
│   ├── index.html
│   └── admin.js
├── uploads/
├── .env
├── requirements.txt
└── README.md
```

## API Endpoints

### Auth Endpoints

- `POST /auth/register` - Register a new user
- `POST /auth/login` - User login

### Incident Endpoints

- `POST /incidents/` - Create a new incident
- `POST /incidents/livestream` - Create a new incident with livestream
- `GET /incidents/media/{incident_id}` - Get incident media file
- `GET /incidents/video/{incident_id}` - Get incident video file
- `GET /incidents/user` - Get current user's incidents

### Admin Endpoints

- `POST /admin/login` - Admin login
- `GET /admin/incidents` - Get all incidents
- `GET /admin/incidents/{incident_id}` - Get specific incident
- `PATCH /admin/incidents/{incident_id}` - Update incident status and remarks
- `GET /admin/incidents/file/{incident_id}` - Get incident file
- `GET /admin/incidents/video/{incident_id}` - Get incident video
- `GET /admin/users` - Get all users (admin only)
- `GET /admin/users/{user_id}` - Get specific user (admin only)
- `POST /admin/users` - Create new user (admin only)
- `PUT /admin/users/{user_id}` - Update user (admin only)
- `DELETE /admin/users/{user_id}` - Delete user (admin only)
- `GET /admin/stats` - Get admin dashboard statistics
- `GET /admin/reports/incidents` - Generate incident report
- `GET /admin/reports/incidents/csv` - Export incidents to CSV

