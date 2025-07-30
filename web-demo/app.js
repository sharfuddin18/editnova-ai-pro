// EditNova Web Demo App
const API_BASE = 'http://localhost:5001';

// Initialize icons
lucide.createIcons();

// Load stats on page load
document.addEventListener('DOMContentLoaded', function() {
    loadStats();
    initializeTabs();
});

// Tab functionality
function initializeTabs() {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const tabId = this.dataset.tab;
            switchTab(tabId);
        });
    });
}

function switchTab(tabId) {
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        if (btn.dataset.tab === tabId) {
            btn.className = 'tab-btn active bg-purple-600 text-white px-6 py-2 rounded-lg font-medium';
        } else {
            btn.className = 'tab-btn bg-gray-200 text-gray-700 px-6 py-2 rounded-lg font-medium';
        }
    });

    // Show/hide content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.add('hidden');
    });
    document.getElementById(tabId + '-tab').classList.remove('hidden');
}

// Load usage statistics
async function loadStats() {
    try {
        const response = await fetch(`${API_BASE}/api/usage`);
        const stats = await response.json();
        
        const statsGrid = document.getElementById('statsGrid');
        statsGrid.innerHTML = `
            <div class="bg-white p-6 rounded-xl shadow-md feature-hover">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-600 text-sm">Active Users</p>
                        <p class="text-2xl font-bold text-purple-600">${stats.active_users.toLocaleString()}</p>
                    </div>
                    <i data-lucide="users" class="w-8 h-8 text-purple-600"></i>
                </div>
            </div>
            <div class="bg-white p-6 rounded-xl shadow-md feature-hover">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-600 text-sm">Images Edited</p>
                        <p class="text-2xl font-bold text-blue-600">${stats.images_edited.toLocaleString()}</p>
                    </div>
                    <i data-lucide="image" class="w-8 h-8 text-blue-600"></i>
                </div>
            </div>
            <div class="bg-white p-6 rounded-xl shadow-md feature-hover">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-600 text-sm">AI Art Generated</p>
                        <p class="text-2xl font-bold text-green-600">${stats.ai_art_generated.toLocaleString()}</p>
                    </div>
                    <i data-lucide="palette" class="w-8 h-8 text-green-600"></i>
                </div>
            </div>
            <div class="bg-white p-6 rounded-xl shadow-md feature-hover">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-600 text-sm">Files Scanned</p>
                        <p class="text-2xl font-bold text-orange-600">${stats.files_scanned.toLocaleString()}</p>
                    </div>
                    <i data-lucide="shield-check" class="w-8 h-8 text-orange-600"></i>
                </div>
            </div>
        `;
        
        lucide.createIcons();
    } catch (error) {
        console.error('Error loading stats:', error);
        showError('Failed to load statistics');
    }
}

// AI Art Generation
async function generateArt() {
    const description = document.getElementById('artDescription').value;
    const style = document.getElementById('artStyle').value;
    
    if (!description) {
        showError('Please enter an art description');
        return;
    }
    
    const resultDiv = document.getElementById('artResult');
    resultDiv.innerHTML = `
        <div class="flex items-center justify-center py-8">
            <div class="loading w-8 h-8 border-4 border-purple-200 border-t-purple-600 rounded-full"></div>
            <span class="ml-3">Generating AI art...</span>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_BASE}/api/generate-art`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({description, style})
        });
        
        const result = await response.json();
        
        if (result.status === 'success') {
            resultDiv.innerHTML = `
                <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                    <h4 class="font-medium text-green-800">AI Art Generated Successfully!</h4>
                    <p class="text-green-700 mt-1">${result.message}</p>
                    <p class="text-sm text-green-600 mt-2">Generation Time: ${result.generationTime.toFixed(2)}s</p>
                    <div class="mt-3 p-4 bg-gray-100 rounded border-dashed border-2">
                        <p class="text-center text-gray-600">🎨 ${result.imageUrl}</p>
                        <p class="text-xs text-center text-gray-500 mt-1">Art ID: ${result.artId}</p>
                    </div>
                </div>
            `;
        } else {
            showError('Failed to generate art');
        }
    } catch (error) {
        console.error('Error generating art:', error);
        showError('Error generating AI art');
    }
}

// Background Removal Simulation
function simulateBackgroundRemoval() {
    const file = document.getElementById('bgImageUpload').files[0];
    if (!file) return;
    
    const resultDiv = document.getElementById('bgResult');
    resultDiv.innerHTML = `
        <div class="flex items-center justify-center py-8">
            <div class="loading w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full"></div>
            <span class="ml-3">Removing background...</span>
        </div>
    `;
    
    // Simulate API call
    setTimeout(async () => {
        try {
            const response = await fetch(`${API_BASE}/api/remove-background`, {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({imageId: 'demo-image-' + Date.now()})
            });
            
            const result = await response.json();
            
            resultDiv.innerHTML = `
                <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                    <h4 class="font-medium text-green-800">Background Removed!</h4>
                    <p class="text-green-700 mt-1">${result.message}</p>
                    <div class="mt-3 p-4 bg-gray-100 rounded border-dashed border-2">
                        <p class="text-center text-gray-600">📸 ${result.resultUrl}</p>
                        <p class="text-xs text-center text-gray-500 mt-1">Original: ${file.name}</p>
                    </div>
                </div>
            `;
        } catch (error) {
            showError('Error removing background');
        }
    }, 2000);
}

// File Scanner
async function scanFile() {
    const filename = document.getElementById('scanFileName').value;
    
    if (!filename) {
        showError('Please enter a filename to scan');
        return;
    }
    
    const resultDiv = document.getElementById('scanResult');
    resultDiv.innerHTML = `
        <div class="flex items-center justify-center py-8">
            <div class="loading w-8 h-8 border-4 border-green-200 border-t-green-600 rounded-full"></div>
            <span class="ml-3">Scanning file for threats...</span>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_BASE}/api/scan-file`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({filename})
        });
        
        const result = await response.json();
        
        if (result.status === 'success') {
            const isSafe = result.safe;
            const threatCount = result.threats.length;
            
            resultDiv.innerHTML = `
                <div class="bg-${isSafe ? 'green' : 'red'}-50 border border-${isSafe ? 'green' : 'red'}-200 rounded-lg p-4">
                    <h4 class="font-medium text-${isSafe ? 'green' : 'red'}-800">
                        ${isSafe ? '✅ File is Safe' : '⚠️ Threats Detected'}
                    </h4>
                    <p class="text-${isSafe ? 'green' : 'red'}-700 mt-1">
                        Filename: ${result.filename}
                    </p>
                    <p class="text-sm text-${isSafe ? 'green' : 'red'}-600 mt-2">
                        Scan Time: ${result.scanTime.toFixed(2)}s
                    </p>
                    ${threatCount > 0 ? `
                        <div class="mt-3 p-2 bg-red-100 rounded">
                            <p class="text-sm font-medium text-red-800">Threats Found:</p>
                            ${result.threats.map(threat => `<p class="text-xs text-red-700">• ${threat}</p>`).join('')}
                        </div>
                    ` : ''}
                </div>
            `;
        } else {
            showError('Failed to scan file');
        }
    } catch (error) {
        console.error('Error scanning file:', error);
        showError('Error scanning file');
    }
}

// Text Translation
async function translateText() {
    const text = document.getElementById('translateText').value;
    const sourceLang = document.getElementById('sourceLang').value;
    const targetLang = document.getElementById('targetLang').value;
    
    if (!text) {
        showError('Please enter text to translate');
        return;
    }
    
    const resultDiv = document.getElementById('translateResult');
    resultDiv.innerHTML = `
        <div class="flex items-center justify-center py-8">
            <div class="loading w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full"></div>
            <span class="ml-3">Translating text...</span>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_BASE}/api/translate-text`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({text, sourceLang, targetLang})
        });
        
        const result = await response.json();
        
        if (result.status === 'success') {
            resultDiv.innerHTML = `
                <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <h4 class="font-medium text-blue-800">Translation Complete</h4>
                    <div class="mt-3 space-y-2">
                        <div class="p-3 bg-gray-100 rounded">
                            <p class="text-sm text-gray-600">Original (${result.sourceLang}):</p>
                            <p class="font-medium">"${result.originalText}"</p>
                        </div>
                        <div class="p-3 bg-blue-100 rounded">
                            <p class="text-sm text-blue-600">Translated (${result.targetLang}):</p>
                            <p class="font-medium text-blue-800">"${result.translatedText}"</p>
                        </div>
                    </div>
                </div>
            `;
        } else {
            showError('Failed to translate text');
        }
    } catch (error) {
        console.error('Error translating text:', error);
        showError('Error translating text');
    }
}

// QR Code Generation
async function generateQR() {
    const text = document.getElementById('qrText').value;
    const type = document.getElementById('qrType').value;
    
    if (!text) {
        showError('Please enter text or URL for QR code');
        return;
    }
    
    const resultDiv = document.getElementById('qrResult');
    resultDiv.innerHTML = `
        <div class="flex items-center justify-center py-8">
            <div class="loading w-8 h-8 border-4 border-indigo-200 border-t-indigo-600 rounded-full"></div>
            <span class="ml-3">Generating QR code...</span>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_BASE}/api/generate-qr`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({text, type})
        });
        
        const result = await response.json();
        
        if (result.status === 'success') {
            resultDiv.innerHTML = `
                <div class="bg-indigo-50 border border-indigo-200 rounded-lg p-4">
                    <h4 class="font-medium text-indigo-800">QR Code Generated!</h4>
                    <p class="text-indigo-700 mt-1">${result.message}</p>
                    <div class="mt-3 p-4 bg-gray-100 rounded border-dashed border-2">
                        <p class="text-center text-gray-600">📱 ${result.qrUrl}</p>
                        <p class="text-xs text-center text-gray-500 mt-1">QR ID: ${result.qrId}</p>
                    </div>
                </div>
            `;
        } else {
            showError('Failed to generate QR code');
        }
    } catch (error) {
        console.error('Error generating QR code:', error);
        showError('Error generating QR code');
    }
}

// Poster Creation
async function createPoster() {
    const text = document.getElementById('posterText').value;
    const theme = document.getElementById('posterTheme').value;
    
    if (!text) {
        showError('Please enter poster text');
        return;
    }
    
    const resultDiv = document.getElementById('posterResult');
    resultDiv.innerHTML = `
        <div class="flex items-center justify-center py-8">
            <div class="loading w-8 h-8 border-4 border-orange-200 border-t-orange-600 rounded-full"></div>
            <span class="ml-3">Creating poster...</span>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_BASE}/api/create-poster`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({text, theme})
        });
        
        const result = await response.json();
        
        if (result.status === 'success') {
            resultDiv.innerHTML = `
                <div class="bg-orange-50 border border-orange-200 rounded-lg p-4">
                    <h4 class="font-medium text-orange-800">Poster Created!</h4>
                    <p class="text-orange-700 mt-1">${result.message}</p>
                    <div class="mt-3 p-4 bg-gray-100 rounded border-dashed border-2">
                        <p class="text-center text-gray-600">🎨 ${result.imageUrl}</p>
                        <p class="text-xs text-center text-gray-500 mt-1">Poster ID: ${result.posterId}</p>
                    </div>
                </div>
            `;
        } else {
            showError('Failed to create poster');
        }
    } catch (error) {
        console.error('Error creating poster:', error);
        showError('Error creating poster');
    }
}

// User Profile
async function loadUserProfile() {
    const profileDiv = document.getElementById('userProfile');
    profileDiv.innerHTML = `
        <div class="flex items-center justify-center py-4">
            <div class="loading w-6 h-6 border-2 border-purple-200 border-t-purple-600 rounded-full"></div>
            <span class="ml-2">Loading profile...</span>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_BASE}/api/user/profile`);
        const profile = await response.json();
        
        profileDiv.innerHTML = `
            <div class="space-y-3">
                <div class="flex items-center space-x-3">
                    <div class="w-12 h-12 bg-purple-600 rounded-full flex items-center justify-center text-white font-bold">
                        ${profile.username.charAt(0).toUpperCase()}
                    </div>
                    <div>
                        <p class="font-medium">${profile.username}</p>
                        <p class="text-sm text-gray-600">${profile.email}</p>
                    </div>
                </div>
                <div class="flex items-center space-x-2">
                    <span class="px-2 py-1 text-xs rounded-full ${profile.isPremium ? 'bg-gold-100 text-gold-800' : 'bg-gray-100 text-gray-800'}">
                        ${profile.isPremium ? 'Premium' : 'Free'}
                    </span>
                    <span class="text-sm text-gray-600">Total Edits: ${profile.totalEdits}</span>
                </div>
            </div>
        `;
    } catch (error) {
        console.error('Error loading profile:', error);
        showError('Error loading profile');
    }
}

// Achievements
async function loadAchievements() {
    const achievementsDiv = document.getElementById('achievements');
    achievementsDiv.innerHTML = `
        <div class="flex items-center justify-center py-4">
            <div class="loading w-6 h-6 border-2 border-purple-200 border-t-purple-600 rounded-full"></div>
            <span class="ml-2">Loading achievements...</span>
        </div>
    `;
    
    try {
        const response = await fetch(`${API_BASE}/api/achievements`);
        const data = await response.json();
        
        achievementsDiv.innerHTML = `
            <div class="space-y-2">
                ${data.achievements.map(achievement => `
                    <div class="flex items-center space-x-3 p-2 rounded-lg ${achievement.unlocked ? 'bg-green-50' : 'bg-gray-50'}">
                        <div class="text-lg">${achievement.unlocked ? '🏆' : '🔒'}</div>
                        <div>
                            <p class="font-medium text-sm ${achievement.unlocked ? 'text-green-800' : 'text-gray-600'}">${achievement.title}</p>
                            <p class="text-xs text-gray-500">${achievement.description}</p>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    } catch (error) {
        console.error('Error loading achievements:', error);
        showError('Error loading achievements');
    }
}

// Login functionality
document.getElementById('loginBtn').addEventListener('click', async function() {
    const username = prompt('Username:');
    const password = prompt('Password:');
    
    if (!username || !password) return;
    
    try {
        const response = await fetch(`${API_BASE}/api/login`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({username, password})
        });
        
        const result = await response.json();
        
        if (result.status === 'success') {
            alert('Login successful!');
            this.textContent = `Welcome, ${username}`;
            this.disabled = true;
        } else {
            alert('Login failed: ' + result.message);
        }
    } catch (error) {
        console.error('Error logging in:', error);
        alert('Error logging in');
    }
});

// Utility functions
function showError(message) {
    alert(message);
}

function showSuccess(message) {
    alert(message);
}

// Initialize icons after dynamic content
function reinitializeIcons() {
    lucide.createIcons();
}