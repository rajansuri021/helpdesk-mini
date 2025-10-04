# HelpDesk Mini - Setup Guide

## Quick Start (For Judges)

### Prerequisites Check
```powershell
# Check Node.js
node --version  # Should be >= 18.x

# Check PostgreSQL
psql --version  # Should be >= 14.x

# Check Redis
redis-cli ping  # Should return "PONG"
```

### Installation & Setup

1. **Install Dependencies**
```powershell
cd e:\project\codex-5\new-project
npm install
```

2. **Setup Database**

Create PostgreSQL database:
```powershell
# Using psql
psql -U postgres
CREATE DATABASE helpdesk_db;
CREATE USER helpdesk WITH PASSWORD 'helpdesk123';
GRANT ALL PRIVILEGES ON DATABASE helpdesk_db TO helpdesk;
\q
```

Or use Docker:
```powershell
docker run --name helpdesk-postgres -e POSTGRES_PASSWORD=helpdesk123 -e POSTGRES_USER=helpdesk -e POSTGRES_DB=helpdesk_db -p 5432:5432 -d postgres:14
```

3. **Setup Redis**

Using Docker:
```powershell
docker run --name helpdesk-redis -p 6379:6379 -d redis:7
```

Or install locally from: https://redis.io/download

4. **Configure Environment**

The `.env` file is already configured with default values:
```env
DATABASE_URL="postgresql://helpdesk:helpdesk123@localhost:5432/helpdesk_db?schema=public"
JWT_SECRET="your-super-secret-jwt-key-change-in-production"
REDIS_URL="redis://localhost:6379"
PORT=3000
```

5. **Run Database Migrations**
```powershell
npm run prisma:generate
npm run prisma:migrate
```

6. **Seed Database with Test Data**
```powershell
npm run seed
```

This will create:
- 1 Admin user
- 2 Agent users
- 2 Regular users
- 5 Sample tickets with various states

7. **Start the Server**
```powershell
npm run dev
```

The server will start on: http://localhost:3000

### Verify Installation

1. **Check Health Endpoint**
```powershell
curl http://localhost:3000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-04T12:00:00.000Z",
  "database": "connected"
}
```

2. **Check Metadata**
```powershell
curl http://localhost:3000/api/_meta
```

3. **Check Hackathon Manifest**
```powershell
curl http://localhost:3000/.well-known/hackathon.json
```

4. **Test Login**
```powershell
curl -X POST http://localhost:3000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"admin@helpdesk.com\",\"password\":\"admin123\"}'
```

### Access the UI

Open your browser and navigate to:
```
http://localhost:3000
```

The test UI provides:
- Quick login buttons for all test users
- Ticket creation form
- Filtering and search
- Pagination
- API response logging

## Troubleshooting

### Database Connection Error

If you see `Cannot connect to database`:

1. Verify PostgreSQL is running:
```powershell
psql -U helpdesk -d helpdesk_db
```

2. Check DATABASE_URL in `.env` file
3. Ensure database exists and user has permissions

### Redis Connection Error

If you see `Redis connection error`:

1. Verify Redis is running:
```powershell
redis-cli ping
```

2. Check REDIS_URL in `.env` file

### Port Already in Use

If port 3000 is taken:

1. Change PORT in `.env` file
2. Restart the server

### Prisma Migration Issues

If migrations fail:

1. Reset database:
```powershell
npm run prisma:migrate -- reset
```

2. Re-run migrations:
```powershell
npm run prisma:migrate
npm run seed
```

## Testing the API

### Using cURL (PowerShell)

```powershell
# Login
$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"email":"admin@helpdesk.com","password":"admin123"}'

$token = $response.token

# Create Ticket
Invoke-RestMethod -Uri "http://localhost:3000/api/tickets" `
  -Method Post `
  -Headers @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
    "Idempotency-Key" = "test-001"
  } `
  -Body '{"title":"Test Ticket","description":"Testing API","priority":"HIGH"}'

# List Tickets
Invoke-RestMethod -Uri "http://localhost:3000/api/tickets?limit=10&offset=0" `
  -Headers @{"Authorization" = "Bearer $token"}
```

### Using Postman

Import the following collection:

**Base URL**: `http://localhost:3000/api`

**Environment Variables**:
- `base_url`: http://localhost:3000/api
- `token`: (set after login)

## Production Build

```powershell
# Build TypeScript
npm run build

# Start production server
npm start
```

## Docker Deployment (Optional)

Create `Dockerfile`:
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

Build and run:
```powershell
docker build -t helpdesk-mini .
docker run -p 3000:3000 --env-file .env helpdesk-mini
```

## Support

For issues or questions, check:
- README.md for API documentation
- API_EXAMPLES.md for request/response examples
- Server logs for error details
