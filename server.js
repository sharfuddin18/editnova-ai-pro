const http = require('http');
const url = require('url');

const server = http.createServer((req, res) => {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;

  if (path === '/api/usage' && req.method === 'GET') {
    const responseData = {
      active_users: 1203,
      premium_users: 205,
      background_removed: 540,
      files_scanned: 134,
      threats_blocked: 3
    };

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(responseData));

  } else if (path === '/api/toggle-feature' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const feature = data.feature || 'unknown';
        const enabled = data.enabled || false;
        
        const responseData = {
          status: 'success',
          message: `${feature} set to ${enabled}`
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(responseData));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'error', message: 'Invalid JSON' }));
      }
    });

  } else if (path === '/api/login' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const username = data.username || '';
        const password = data.password || '';

        if (username === 'admin' && password === 'editnova2025') {
          const responseData = {
            status: 'success',
            token: 'fake-jwt-token'
          };
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(responseData));
        } else {
          const responseData = {
            status: 'error',
            message: 'Invalid credentials'
          };
          res.writeHead(401, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(responseData));
        }
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'error', message: 'Invalid JSON' }));
      }
    });

  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'error', message: 'Not found' }));
  }
});

const PORT = 5001;
server.listen(PORT, () => {
  console.log(`EditNova API Server running on port ${PORT}`);
  console.log('Available endpoints:');
  console.log('  GET  /api/usage');
  console.log('  POST /api/toggle-feature');
  console.log('  POST /api/login');
  console.log(`Server running at http://localhost:${PORT}`);
});