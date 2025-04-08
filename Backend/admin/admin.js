
// Global variables
let token = localStorage.getItem('adminToken') || '';
let currentIncidentId = null;
let currentUserData = null;
const API_URL = 'http://127.0.0.1:8000'; // This should match your server URL

// DOM Elements
const loginForm = document.getElementById('loginForm');
const adminDashboard = document.getElementById('adminDashboard');
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const loginBtn = document.getElementById('loginBtn');
const loginError = document.getElementById('loginError');
const logoutBtn = document.getElementById('logoutBtn');
const logoutDropdownBtn = document.getElementById('logoutDropdownBtn');
const incidentsList = document.getElementById('incidentsList');
const usersList = document.getElementById('usersList');
const incidentSearch = document.getElementById('incidentSearch');
const statusFilter = document.getElementById('statusFilter');
const userSearch = document.getElementById('userSearch');
const dashboardStats = document.getElementById('dashboardStats');
const adminUsername = document.getElementById('adminUsername');
const adminLevelBadge = document.getElementById('adminLevelBadge');
const avatarInitial = document.getElementById('avatarInitial');
const reportStatusFilter = document.getElementById('reportStatusFilter');
const generateReportBtn = document.getElementById('generateReportBtn');
const exportReportBtn = document.getElementById('exportReportBtn');
const reportStats = document.getElementById('reportStats');
const reportIncidentsList = document.getElementById('reportIncidentsList');
const exportIncidentsBtn = document.getElementById('exportIncidentsBtn');
const addUserBtn = document.getElementById('addUserBtn');
const userModal = new bootstrap.Modal(document.getElementById('userModal'), {});
const userForm = document.getElementById('userForm');
const userModalTitle = document.getElementById('userModalTitle');
const userIdInput = document.getElementById('userId');
const userEmailInput = document.getElementById('userEmail');
const userPasswordInput = document.getElementById('userPassword');
const userAdminLevelInput = document.getElementById('userAdminLevel');
const saveUserBtn = document.getElementById('saveUserBtn');

// Initialize the app
function init() {
    // Check if the user is logged in
    if (token) {
        showAdminDashboard();
        loadCurrentUser();
        loadDashboardStats();
        loadIncidents();
    } else {
        showLoginForm();
    }
    
    // Event listeners
    loginBtn.addEventListener('click', handleLogin);
    logoutBtn.addEventListener('click', handleLogout);
    logoutDropdownBtn.addEventListener('click', handleLogout);
    incidentSearch.addEventListener('input', filterIncidents);
    statusFilter.addEventListener('change', filterIncidents);
    userSearch.addEventListener('input', filterUsers);
    generateReportBtn.addEventListener('click', generateReport);
    exportReportBtn.addEventListener('click', exportReportToCSV);
    exportIncidentsBtn.addEventListener('click', exportIncidentsToCSV);
    addUserBtn.addEventListener('click', showAddUserModal);
    saveUserBtn.addEventListener('click', saveUser);
    
    // Status update event delegation
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('status-update')) {
            e.preventDefault();
            const status = e.target.getAttribute('data-status');
            updateIncidentStatus(currentIncidentId, status);
        }
        
        if (e.target.classList.contains('save-remarks')) {
            e.preventDefault();
            const incidentId = e.target.getAttribute('data-id');
            const remarks = document.getElementById('adminRemarks').value;
            updateIncidentRemarks(incidentId, remarks);
        }
        
        if (e.target.classList.contains('edit-user')) {
            e.preventDefault();
            const userId = e.target.getAttribute('data-id');
            showEditUserModal(userId);
        }
        
        if (e.target.classList.contains('delete-user')) {
            e.preventDefault();
            const userId = e.target.getAttribute('data-id');
            deleteUser(userId);
        }
        
        if (e.target.classList.contains('view-details')) {
            e.preventDefault();
            const incidentId = e.target.getAttribute('data-id');
            showIncidentDetails(incidentId);
        }
    });

    // Tab change event delegation
    document.querySelectorAll('[data-bs-toggle="tab"]').forEach(tab => {
        tab.addEventListener('click', function(e) {
            const targetTab = this.getAttribute('href').substring(1);
            if (targetTab === 'users' && usersList.innerHTML === '') {
                loadUsers();
            } else if (targetTab === 'dashboard') {
                loadDashboardStats();
            }
        });
    });
}

async function loadCurrentUser() {
    try {
        // Temporary workaround if /user/profile endpoint doesn't exist yet
        // Create a mock user based on the JWT token
        const tokenParts = token.split('.');
        if (tokenParts.length === 3) {
            try {
                const payload = JSON.parse(atob(tokenParts[1]));
                currentUserData = {
                    email: payload.sub,
                    admin_level: payload.admin_level || 2,
                    is_admin: true
                };
                
                // Update UI with user data
                adminUsername.textContent = currentUserData.email.split('@')[0];
                avatarInitial.textContent = currentUserData.email[0].toUpperCase();
                
                // Set admin level badge
                if (currentUserData.admin_level === 2) {
                    adminLevelBadge.textContent = 'Admin';
                    adminLevelBadge.className = 'badge admin-level-admin me-3';
                } else if (currentUserData.admin_level === 1) {
                    adminLevelBadge.textContent = 'Operator';
                    adminLevelBadge.className = 'badge admin-level-operator me-3';
                } else {
                    adminLevelBadge.textContent = 'User';
                    adminLevelBadge.className = 'badge bg-secondary me-3';
                }
                
                // Hide admin-only features for operators
                if (currentUserData.admin_level < 2) {
                    document.querySelectorAll('.admin-only').forEach(el => {
                        el.style.display = 'none';
                    });
                }
                
                return;
            } catch (e) {
                console.error("Error parsing token:", e);
            }
        }
        
        // If the token parsing failed or the workaround is not needed,
        // proceed with the original API call
        const response = await fetch(`${API_URL}/user/profile`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            if (response.status === 401) {
                handleLogout();
                throw new Error('Session expired. Please log in again.');
            }
            throw new Error('Failed to load user profile');
        }
        
        currentUserData = await response.json();
        
        // Update UI with user data
        if (currentUserData) {
            adminUsername.textContent = currentUserData.email.split('@')[0];
            avatarInitial.textContent = currentUserData.email[0].toUpperCase();
            
            // Set admin level badge
            if (currentUserData.admin_level === 2) {
                adminLevelBadge.textContent = 'Admin';
                adminLevelBadge.className = 'badge admin-level-admin me-3';
            } else if (currentUserData.admin_level === 1) {
                adminLevelBadge.textContent = 'Operator';
                adminLevelBadge.className = 'badge admin-level-operator me-3';
            } else {
                adminLevelBadge.textContent = 'User';
                adminLevelBadge.className = 'badge bg-secondary me-3';
            }
            
            // Hide admin-only features for operators
            if (currentUserData.admin_level < 2) {
                document.querySelectorAll('.admin-only').forEach(el => {
                    el.style.display = 'none';
                });
            }
        }
        
    } catch (error) {
        console.error('Error loading user profile:', error);
    }
}

// Handle login with loading indicator
async function handleLogin() {
    const email = emailInput.value.trim();
    const password = passwordInput.value;
    
    if (!email || !password) {
        loginError.textContent = 'Please enter email and password';
        return;
    }
    
    // Clear previous error
    loginError.textContent = '';
    
    // Show loading state
    loginBtn.disabled = true;
    loginBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Logging in...';
    
    try {
        console.log("Making login request to:", `${API_URL}/admin/login`);
        
        const response = await fetch(`${API_URL}/admin/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password })
        });
        
        console.log("Login response status:", response.status);
        
        const data = await response.json();
        console.log("Login response data:", data);
        
        if (!response.ok) {
            throw new Error(data.detail || 'Login failed');
        }
        
        // Store the token
        token = data.access_token;
        localStorage.setItem('adminToken', token);
        
        console.log("Token stored, showing dashboard");
        
        // Show the admin dashboard and load data
        showAdminDashboard();
        loadCurrentUser();
        loadDashboardStats();
        loadIncidents();
        
    } catch (error) {
        console.error("Login error:", error);
        loginError.textContent = error.message;
    } finally {
        // Reset button state
        loginBtn.disabled = false;
        loginBtn.textContent = 'Login';
    }
}
// Handle logout
function handleLogout() {
    token = '';
    currentUserData = null;
    localStorage.removeItem('adminToken');
    showLoginForm();
}

// Show login form
function showLoginForm() {
    loginForm.style.display = 'block';
    adminDashboard.style.display = 'none';
    emailInput.value = '';
    passwordInput.value = '';
    loginError.textContent = '';
}

function showAdminDashboard() {
    loginForm.style.display = 'none';
    adminDashboard.style.display = 'block';
    console.log("Admin dashboard shown");
}

// Load dashboard statistics
async function loadDashboardStats() {
    dashboardStats.innerHTML = `
        <div class="text-center py-5">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
            <p class="mt-2">Loading dashboard data...</p>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_URL}/admin/stats`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            if (response.status === 401) {
                handleLogout();
                throw new Error('Session expired. Please log in again.');
            }
            throw new Error('Failed to load statistics');
        }
        
        const stats = await response.json();
        displayDashboardStats(stats);
        
    } catch (error) {
        dashboardStats.innerHTML = `<div class="alert alert-danger">${error.message}</div>`;
    }
}
// Load all incidents with loading indicator
async function loadIncidents() {
    incidentsList.innerHTML = `
        <div class="text-center p-4">
            <div class="spinner-border" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
            <p class="mt-2">Loading incidents...</p>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_URL}/admin/incidents`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            if (response.status === 401) {
                handleLogout();
                throw new Error('Session expired. Please log in again.');
            }
            throw new Error('Failed to load incidents');
        }
        
        const incidents = await response.json();
        displayIncidents(incidents);
        
    } catch (error) {
        console.error('Error loading incidents:', error);
        incidentsList.innerHTML = `<div class="alert alert-danger">${error.message}</div>`;
    }
}
// Display incidents with a better UI
function displayIncidents(incidents) {
    if (incidents.length === 0) {
        incidentsList.innerHTML = '<div class="alert alert-info">No incidents found</div>';
        return;
    }
    
    const html = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Title</th>
                        <th>Date</th>
                        <th>Status</th>
                        <th>Media</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    ${incidents.map(incident => `
                        <tr class="incident-item" data-id="${incident.id}" data-title="${incident.title}" data-status="${incident.status}">
                            <td>${incident.id}</td>
                            <td>${incident.title}</td>
                            <td>${incident.created_at ? new Date(incident.created_at).toLocaleString() : '-'}</td>
                            <td><span class="badge status-${incident.status}">${formatStatus(incident.status)}</span></td>
                            <td>${getMediaIcons(incident)}</td>
                            <td>
                                <button class="btn btn-sm btn-primary view-details" data-id="${incident.id}">View</button>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    
    incidentsList.innerHTML = html;
    
    // Add event listeners to view details buttons
    document.querySelectorAll('.view-details').forEach(button => {
        button.addEventListener('click', function() {
            const incidentId = this.getAttribute('data-id');
            showIncidentDetails(incidentId);
        });
    });
}
// Get media icons for incidents - with safety checks
function getMediaIcons(incident) {
    let icons = '';
    
    if (incident.media_url) {
        icons += '<i class="fas fa-image text-primary me-2" title="Has image"></i>';
    }
    
    // Only check for video_url if the property exists
    if (incident.hasOwnProperty('video_url') && incident.video_url) {
        icons += '<i class="fas fa-video text-danger me-2" title="Has video"></i>';
    }
    
    // Only check for livestream_url if the property exists
    if (incident.hasOwnProperty('livestream_url') && incident.livestream_url) {
        icons += '<i class="fas fa-broadcast-tower text-warning" title="Has livestream"></i>';
    }
    
    return icons || '-';
}
// Show incident details with better UI - with safety checks for optional fields
async function showIncidentDetails(incidentId) {
    currentIncidentId = incidentId;
    
    // Show loading modal
    const modalBody = document.getElementById('incidentModalBody');
    modalBody.innerHTML = `
        <div class="text-center p-4">
            <div class="spinner-border" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
            <p class="mt-2">Loading incident details...</p>
        </div>
    `;
    
    const modal = new bootstrap.Modal(document.getElementById('incidentModal'));
    modal.show();
    
    try {
        const response = await fetch(`${API_URL}/admin/incidents/${incidentId}`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            throw new Error('Failed to load incident details');
        }
        
        const incident = await response.json();
        
        // Update modal content with incident details, with checks for optional fields
        modalBody.innerHTML = `
            <div class="row">
                <div class="col-md-8">
                    <div class="d-flex justify-content-between mb-3">
                        <h4>${incident.title}</h4>
                        <span class="badge bg-${getStatusColor(incident.status)} fs-6">${formatStatus(incident.status)}</span>
                    </div>
                    <div class="mb-3">
                        <p class="text-muted mb-1">Reported by: User #${incident.user_id}</p>
                        <p class="text-muted mb-1">Date: ${incident.created_at ? new Date(incident.created_at).toLocaleString() : 'Unknown'}</p>
                    </div>
                    <div class="card mb-3">
                        <div class="card-header">Description</div>
                        <div class="card-body">
                            <p>${incident.description || 'No description provided'}</p>
                        </div>
                    </div>
                    <div class="card mb-3">
                        <div class="card-header">Location</div>
                        <div class="card-body">
                            <p>Latitude: ${incident.latitude}, Longitude: ${incident.longitude}</p>
                            <div id="map" style="height: 300px; background-color: #eee; margin-bottom: 15px;">
                                <a href="https://www.google.com/maps?q=${incident.latitude},${incident.longitude}" target="_blank" class="btn btn-sm btn-outline-secondary">
                                    View on Google Maps
                                </a>
                            </div>
                        </div>
                    </div>
                    <div class="card mb-3">
                        <div class="card-header">Admin Remarks</div>
                        <div class="card-body">
                            <textarea id="adminRemarks" class="form-control mb-2" rows="3">${incident.admin_remarks || ''}</textarea>
                            <button class="btn btn-sm btn-primary save-remarks" data-id="${incident.id}">Save Remarks</button>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card mb-3">
                        <div class="card-header">Evidence</div>
                        <div class="card-body">
                            <!-- Image evidence -->
                            ${incident.media_url ? `
                                <div class="text-center mb-3">
                                    <img src="${API_URL}/admin/incidents/file/${incident.id}" class="img-fluid img-thumbnail" alt="Evidence">
                                    <a href="${API_URL}/admin/incidents/file/${incident.id}" target="_blank" class="btn btn-sm btn-outline-secondary mt-2 d-block">
                                        View Original
                                    </a>
                                </div>
                            ` : ''}
                            
                            <!-- Video evidence - only if video_url exists -->
                            ${incident.hasOwnProperty('video_url') && incident.video_url ? `
                                <div class="text-center mb-3">
                                    <video width="100%" controls>
                                        <source src="${API_URL}/admin/incidents/video/${incident.id}" type="video/mp4">
                                        Your browser does not support the video tag.
                                    </video>
                                    <a href="${API_URL}/admin/incidents/video/${incident.id}" target="_blank" class="btn btn-sm btn-outline-secondary mt-2 d-block">
                                        Download Video
                                    </a>
                                </div>
                            ` : ''}
                            
                            <!-- Livestream - only if livestream_url exists -->
                            ${incident.hasOwnProperty('livestream_url') && incident.livestream_url ? `
                                <div class="text-center mb-3">
                                    <div class="alert alert-info">
                                        <i class="fas fa-broadcast-tower me-2"></i> This incident has a livestream
                                    </div>
                                    <a href="${incident.livestream_url}" target="_blank" class="btn btn-sm btn-outline-secondary mt-2 d-block">
                                        Open Livestream
                                    </a>
                                </div>
                            ` : ''}
                            
                            ${!incident.media_url && !(incident.hasOwnProperty('video_url') && incident.video_url) && !(incident.hasOwnProperty('livestream_url') && incident.livestream_url) ? '<p class="text-center">No evidence attached</p>' : ''}
                        </div>
                    </div>
                    <div class="card mb-3">
                        <div class="card-header">Status History</div>
                        <div class="card-body">
                            <ul class="list-group">
                                <li class="list-group-item ${incident.status === 'submitted' ? 'active' : ''}">
                                    <i class="fas fa-circle me-2 ${incident.status === 'submitted' ? 'text-white' : 'text-warning'}"></i> Submitted
                                </li>
                                <li class="list-group-item ${incident.status === 'under_process' ? 'active' : ''}">
                                    <i class="fas fa-circle me-2 ${incident.status === 'under_process' ? 'text-white' : 'text-info'}"></i> Under Process
                                </li>
                                <li class="list-group-item ${incident.status === 'resolved' ? 'active' : ''}">
                                    <i class="fas fa-circle me-2 ${incident.status === 'resolved' ? 'text-white' : 'text-success'}"></i> Resolved
                                </li>
                                <li class="list-group-item ${incident.status === 'rejected' ? 'active' : ''}">
                                    <i class="fas fa-circle me-2 ${incident.status === 'rejected' ? 'text-white' : 'text-danger'}"></i> Rejected
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
    } catch (error) {
        console.error('Error showing incident details:', error);
        modalBody.innerHTML = `<div class="alert alert-danger">${error.message}</div>`;
    }
}
// Load all users
async function loadUsers() {
    usersList.innerHTML = `
        <div class="text-center p-4">
            <div class="spinner-border" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
            <p class="mt-2">Loading users...</p>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_URL}/admin/users`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            if (response.status === 401) {
                handleLogout();
                throw new Error('Session expired. Please log in again.');
            }
            throw new Error('Failed to load users');
        }
        
        const users = await response.json();
        displayUsers(users);
        
    } catch (error) {
        console.error('Error loading users:', error);
        usersList.innerHTML = `<div class="alert alert-danger">${error.message}</div>`;
    }
}

// Display users
function displayUsers(users) {
    if (users.length === 0) {
        usersList.innerHTML = '<div class="alert alert-info">No users found</div>';
        return;
    }
    
    const html = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Email</th>
                        <th>Admin Level</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    ${users.map(user => `
                        <tr class="user-item" data-id="${user.id}" data-email="${user.email}">
                            <td>${user.id}</td>
                            <td>${user.email}</td>
                            <td>${getAdminLevelText(user.admin_level)}</td>
                            <td>
                                <button class="btn btn-sm btn-primary edit-user" data-id="${user.id}">Edit</button>
                                <button class="btn btn-sm btn-danger delete-user" data-id="${user.id}">Delete</button>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    
    usersList.innerHTML = html;
}

// Get admin level text
function getAdminLevelText(level) {
    if (level === 2) {
        return '<span class="badge admin-level-admin">Admin</span>';
    } else if (level === 1) {
        return '<span class="badge admin-level-operator">Operator</span>';
    } else {
        return '<span class="badge bg-secondary">User</span>';
    }
}
// Display dashboard statistics
function displayDashboardStats(stats) {
    // For backwards compatibility with the API response
    const submittedCount = stats.pending_incidents;
    const underProcessCount = stats.in_progress_incidents;
    
    dashboardStats.innerHTML = `
        <div class="row">
            <div class="col-md-3">
                <div class="card bg-primary text-white mb-4">
                    <div class="card-body">
                        <h5 class="card-title">Total Incidents</h5>
                        <h2 class="display-4">${stats.total_incidents}</h2>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card bg-warning text-white mb-4">
                    <div class="card-body">
                        <h5 class="card-title">Submitted</h5>
                        <h2 class="display-4">${submittedCount}</h2>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card bg-info text-white mb-4">
                    <div class="card-body">
                        <h5 class="card-title">Under Process</h5>
                        <h2 class="display-4">${underProcessCount}</h2>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card bg-success text-white mb-4">
                    <div class="card-body">
                        <h5 class="card-title">Resolved</h5>
                        <h2 class="display-4">${stats.resolved_incidents}</h2>
                    </div>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-md-6">
                <div class="card mb-4">
                    <div class="card-header">
                        <i class="fas fa-chart-pie me-1"></i>
                        Incidents by Status
                    </div>
                    <div class="card-body">
                        <canvas id="statusChart" width="100%" height="40"></canvas>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card mb-4">
                    <div class="card-header">
                        <i class="fas fa-chart-bar me-1"></i>
                        Recent Activity
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-bordered" width="100%" cellspacing="0">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Title</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${stats.recent_incidents.map(incident => `
                                        <tr>
                                            <td>${incident.id}</td>
                                            <td><a href="#" class="view-details" data-id="${incident.id}">${incident.title}</a></td>
                                            <td><span class="badge status-${incident.status}">${formatStatus(incident.status)}</span></td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-md-6">
                <div class="card mb-4">
                    <div class="card-header">
                        <i class="fas fa-users me-1"></i>
                        User Statistics
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="card bg-secondary text-white mb-3">
                                    <div class="card-body text-center">
                                        <h5 class="card-title">Total Users</h5>
                                        <h2 class="display-5">${stats.total_users}</h2>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="card bg-danger text-white mb-3">
                                    <div class="card-body text-center">
                                        <h5 class="card-title">Admins</h5>
                                        <h2 class="display-5">${stats.admin_users}</h2>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card mb-4">
                    <div class="card-header">
                        <i class="fas fa-tasks me-1"></i>
                        System Health
                    </div>
                    <div class="card-body">
                        <h4 class="text-center">System Status: <span class="text-success">Online</span></h4>
                        <div class="progress mb-3 mt-4">
                            <div class="progress-bar bg-success" role="progressbar" style="width: 100%" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100">API: 100%</div>
                        </div>
                        <div class="progress mb-3">
                            <div class="progress-bar bg-success" role="progressbar" style="width: 100%" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100">Database: 100%</div>
                        </div>
                        <div class="progress">
                            <div class="progress-bar bg-success" role="progressbar" style="width: 100%" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100">Storage: 100%</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    // Initialize status chart
    const ctx = document.getElementById('statusChart');
    new Chart(ctx, {
        type: 'pie',
        data: {
            labels: ['Submitted', 'Under Process', 'Resolved', 'Rejected'],
            datasets: [{
                data: [
                    submittedCount,
                    underProcessCount,
                    stats.resolved_incidents,
                    stats.rejected_incidents
                ],
                backgroundColor: [
                    '#ffc107', // Warning
                    '#0dcaf0', // Info
                    '#198754', // Success
                    '#dc3545'  // Danger
                ]
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    position: 'right'
                }
            }
        }
    });
    
    // Add event listeners to view details links
    document.querySelectorAll('.view-details').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const incidentId = this.getAttribute('data-id');
            showIncidentDetails(incidentId);
        });
    });
}
// Export report to CSV
function exportReportToCSV() {
    const table = document.getElementById('reportTable');
    if (!table) {
        alert('Please generate a report first');
        return;
    }
    
    exportTableToCSV(table, 'incident_report.csv');
}

// Export incidents to CSV
function exportIncidentsToCSV() {
    const table = document.querySelector('#incidentsList table');
    if (!table) {
        alert('No incidents data to export');
        return;
    }
    
    exportTableToCSV(table, 'incidents.csv');
}

// Helper function to export table to CSV
function exportTableToCSV(table, filename) {
    let csv = [];
    const rows = table.querySelectorAll('tr');
    
    for (let i = 0; i < rows.length; i++) {
        const row = [], cols = rows[i].querySelectorAll('td, th');
        
        for (let j = 0; j < cols.length; j++) {
            // Get text content and clean it for CSV
            let text = cols[j].textContent.trim();
            // Replace commas with semicolons to avoid CSV parsing issues
            text = text.replace(/,/g, ';');
            // Wrap in quotes to handle special characters
            row.push(`"${text}"`);
        }
        
        csv.push(row.join(','));
    }
    
    // Create and download the CSV file
    const csvContent = 'data:text/csv;charset=utf-8,' + csv.join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', filename);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
// Format status strings for display
function formatStatus(status) {
    if (status === 'submitted' || status === 'pending') {
        return 'Submitted';
    } else if (status === 'under_process' || status === 'in_progress') {
        return 'Under Process';
    } else if (status === 'resolved') {
        return 'Resolved';
    } else if (status === 'rejected') {
        return 'Rejected';
    }
    return status.charAt(0).toUpperCase() + status.slice(1).replace('_', ' ');
}

// Get status color for badges and UI elements
function getStatusColor(status) {
    if (status === 'submitted' || status === 'pending') {
        return 'warning';
    } else if (status === 'under_process' || status === 'in_progress') {
        return 'info';
    } else if (status === 'resolved') {
        return 'success';
    } else if (status === 'rejected') {
        return 'danger';
    }
    return 'secondary';
}

// Update incident status
async function updateIncidentStatus(incidentId, status) {
    try {
        const response = await fetch(`${API_URL}/admin/incidents/${incidentId}`, {
            method: 'PATCH',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ status })
        });
        
        if (!response.ok) {
            throw new Error('Failed to update status');
        }
        
        // Show success toast
        const toastEl = document.getElementById('statusToast');
        const toast = new bootstrap.Toast(toastEl);
        document.getElementById('toastMessage').textContent = 'Status updated successfully!';
        toast.show();
        
        // Refresh incident details
        showIncidentDetails(incidentId);
        
        // Also refresh the incidents list if it's visible
        if (document.querySelector('.nav-link[href="#incidents"]').classList.contains('active')) {
            loadIncidents();
        }
        
    } catch (error) {
        alert(error.message);
    }
}

// Update incident remarks
async function updateIncidentRemarks(incidentId, remarks) {
    try {
        const response = await fetch(`${API_URL}/admin/incidents/${incidentId}`, {
            method: 'PATCH',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ admin_remarks: remarks })
        });
        
        if (!response.ok) {
            throw new Error('Failed to update remarks');
        }
        
        // Show success toast
        const toastEl = document.getElementById('statusToast');
        const toast = new bootstrap.Toast(toastEl);
        document.getElementById('toastMessage').textContent = 'Remarks updated successfully!';
        toast.show();
        
    } catch (error) {
        alert(error.message);
    }
}

// Show add user modal
function showAddUserModal() {
    userModalTitle.textContent = 'Add New User';
    userIdInput.value = '';
    userEmailInput.value = '';
    userPasswordInput.value = '';
    userPasswordInput.disabled = false;
    userPasswordInput.required = true;
    userAdminLevelInput.value = '0';
    userModal.show();
}

// Show edit user modal
async function showEditUserModal(userId) {
    userModalTitle.textContent = 'Edit User';
    userIdInput.value = userId;
    
    try {
        const response = await fetch(`${API_URL}/admin/users/${userId}`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            throw new Error('Failed to load user details');
        }
        
        const user = await response.json();
        
        userEmailInput.value = user.email;
        userPasswordInput.value = '';
        userPasswordInput.disabled = false;
        userPasswordInput.required = false;
        userAdminLevelInput.value = user.admin_level?.toString() || '0';
        
        userModal.show();
        
    } catch (error) {
        alert(error.message);
    }
}

// Delete user
async function deleteUser(userId) {
    if (!confirm('Are you sure you want to delete this user?')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_URL}/admin/users/${userId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            throw new Error('Failed to delete user');
        }
        
        // Show success toast
        const toastEl = document.getElementById('statusToast');
        const toast = new bootstrap.Toast(toastEl);
        document.getElementById('toastMessage').textContent = 'User deleted successfully!';
        toast.show();
        
        // Reload users list
        loadUsers();
        
    } catch (error) {
        alert(error.message);
    }
}

// Save user (add or update)
async function saveUser() {
    const userId = userIdInput.value;
    const email = userEmailInput.value.trim();
    const password = userPasswordInput.value;
    const adminLevel = parseInt(userAdminLevelInput.value);
    
    if (!email) {
        alert('Please enter email');
        return;
    }
    
    if (!userId && !password) {
        alert('Please enter password');
        return;
    }
    
    const userData = {
        email,
        admin_level: adminLevel,
        is_admin: adminLevel > 0
    };
    
    if (password) {
        userData.password = password;
    }
    
    try {
        let url = `${API_URL}/admin/users`;
        let method = 'POST';
        
        if (userId) {
            url += `/${userId}`;
            method = 'PUT';
        }
        
        const response = await fetch(url, {
            method,
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(userData)
        });
        
        if (!response.ok) {
            throw new Error('Failed to save user');
        }
        
        // Hide modal and reload users list
        userModal.hide();
        loadUsers();
        
        // Show success toast
        const toastEl = document.getElementById('statusToast');
        const toast = new bootstrap.Toast(toastEl);
        document.getElementById('toastMessage').textContent = userId ? 'User updated successfully!' : 'User added successfully!';
        toast.show();
        
    } catch (error) {
        alert(error.message);
    }
}

// Filter incidents based on search and status filter
function filterIncidents() {
    const searchTerm = incidentSearch.value.toLowerCase();
    const statusValue = statusFilter.value;
    
    const rows = document.querySelectorAll('#incidentsList .incident-item');
    
    rows.forEach(row => {
        const title = row.getAttribute('data-title').toLowerCase();
        const status = row.getAttribute('data-status');
        
        const matchesSearch = !searchTerm || title.includes(searchTerm);
        const matchesStatus = statusValue === 'all' || status === statusValue;
        
        row.style.display = matchesSearch && matchesStatus ? '' : 'none';
    });
}

// Filter users based on search
function filterUsers() {
    const searchTerm = userSearch.value.toLowerCase();
    
    const rows = document.querySelectorAll('#usersList .user-item');
    
    rows.forEach(row => {
        const email = row.getAttribute('data-email').toLowerCase();
        
        const matchesSearch = !searchTerm || email.includes(searchTerm);
        
        row.style.display = matchesSearch ? '' : 'none';
    });
}

// Generate report
async function generateReport() {
    const statusValue = reportStatusFilter.value;
    
    reportStats.innerHTML = `
        <div class="text-center py-5">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
            <p class="mt-2">Generating report...</p>
        </div>
    `;
    
    reportIncidentsList.innerHTML = '';
    
    try {
        let url = `${API_URL}/admin/reports/incidents`;
        if (statusValue) {
            url += `?status=${statusValue}`;
        }
        
        const response = await fetch(url, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (!response.ok) {
            throw new Error('Failed to generate report');
        }
        
        const reportData = await response.json();
        displayReport(reportData);
        
    } catch (error) {
        reportStats.innerHTML = `<div class="alert alert-danger">${error.message}</div>`;
    }
}

// Display report
function displayReport(reportData) {
    // Display statistics
    const statsHtml = `
        <div class="col-md-3">
            <div class="card bg-primary text-white mb-4">
                <div class="card-body">
                    <h5 class="card-title">Total Incidents</h5>
                    <h2 class="display-4">${reportData.total_incidents}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card bg-warning text-white mb-4">
                <div class="card-body">
                    <h5 class="card-title">Submitted</h5>
                    <h2 class="display-4">${reportData.by_status.submitted}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card bg-info text-white mb-4">
                <div class="card-body">
                    <h5 class="card-title">Under Process</h5>
                    <h2 class="display-4">${reportData.by_status.under_process}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card bg-success text-white mb-4">
                <div class="card-body">
                    <h5 class="card-title">Resolved</h5>
                    <h2 class="display-4">${reportData.by_status.resolved}</h2>
                </div>
            </div>
        </div>
    `;
    
    reportStats.innerHTML = statsHtml;
    
    // Display incidents table
    const tableHtml = `
        <div class="table-responsive">
            <table class="table table-bordered" id="reportTable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Title</th>
                        <th>Status</th>
                        <th>User ID</th>
                        <th>Admin Remarks</th>
                        <th>Created</th>
                    </tr>
                </thead>
                <tbody>
                    ${reportData.incidents.map(incident => `
                        <tr>
                            <td>${incident.id}</td>
                            <td>${incident.title}</td>
                            <td><span class="badge status-${incident.status}">${formatStatus(incident.status)}</span></td>
                            <td>${incident.user_id}</td>
                            <td>${incident.admin_remarks || '-'}</td>
                            <td>${incident.created_at ? new Date(incident.created_at).toLocaleString() : '-'}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    
    reportIncidentsList.innerHTML = tableHtml;
}
// Initialize the app when the DOM is loaded
document.addEventListener('DOMContentLoaded', init);