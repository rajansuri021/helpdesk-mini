# 🚀 Deployment Guide - HelpDesk Mini

## ✅ Hackathon Compliance Checklist

### Required Endpoints ✅
- ✅ `POST /api/auth/register` - User registration
- ✅ `POST /api/auth/login` - User login
- ✅ `POST /api/tickets` - Create ticket (with Idempotency-Key)
- ✅ `GET /api/tickets` - List tickets (with pagination)
- ✅ `GET /api/tickets/:id` - Get ticket details
- ✅ `PATCH /api/tickets/:id` - Update ticket (with optimistic locking)
- ✅ `POST /api/tickets/:id/comments` - Add comment (with Idempotency-Key)
- ✅ `GET /api/health` - Health check
- ✅ `GET /api/_meta` - Metadata
- ✅ `GET /.well-known/hackathon.json` - Hackathon manifest

### Required Features ✅
- ✅ **Pagination**: `?limit=10&offset=0` returns `{items: [...], next_offset: 10}`
- ✅ **Idempotency**: POST endpoints accept `Idempotency-Key` header
- ✅ **Rate Limiting**: 60 requests/minute/user, returns 429 when exceeded
- ✅ **Error Format**: `{"error": {"code": "...", "message": "...", "field": "..."}}`
- ✅ **CORS**: Enabled for all origins
- ✅ **Authentication**: JWT-based with Bearer tokens

### Additional Features ✅
- ✅ Role-based access control (USER, AGENT, ADMIN)
- ✅ SLA tracking with automatic breach detection
- ✅ Optimistic locking (version-based conflict resolution)
- ✅ Complete timeline/audit trail
- ✅ Threaded comments system
- ✅ Advanced search and filtering
- ✅ User registration with admin approval for agents
- ✅ Modern, professional UI

---

## 🌐 Deployment Options

### Option 1: Render.com (Recommended - Free Tier)

**Why Render?**
- ✅ Free tier available
- ✅ Automatic deployments from GitHub
- ✅ Built-in PostgreSQL database
- ✅ SSL certificates included
- ✅ Easy environment variables

**Steps:**

1. **Prepare Repository**
```bash
# Initialize git (if not already)
git init
git add .
git commit -m "Initial commit - HelpDesk Mini"

# Create GitHub repository and push
git remote add origin https://github.com/YOUR_USERNAME/helpdesk-mini.git
git branch -M main
git push -u origin main
```

2. **Update for PostgreSQL** (Render uses PostgreSQL, not SQLite)

Edit `prisma/schema.prisma`:
```prisma
datasource db {
  provider = "postgresql"  // Change from sqlite
  url      = env("DATABASE_URL")
}
```

3. **Create Render Account**
- Go to https://render.com
- Sign up with GitHub
- Click "New +" → "Web Service"
- Connect your GitHub repository

4. **Configure Web Service**
```
Name: helpdesk-mini
Environment: Node
Build Command: npm install && npx prisma generate && npx prisma migrate deploy
Start Command: npm run start
```

5. **Add Environment Variables**
```
NODE_ENV=production
DATABASE_URL=<provided by Render PostgreSQL>
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRES_IN=7d
PORT=3000
CORS_ORIGIN=*
```

6. **Add PostgreSQL Database**
- In Render dashboard, click "New +" → "PostgreSQL"
- Connect it to your web service
- Copy the "Internal Database URL" to `DATABASE_URL`

7. **Deploy**
- Click "Create Web Service"
- Wait for build and deployment
- Your app will be live at: `https://helpdesk-mini.onrender.com`

---

### Option 2: Railway.app (Alternative - Free Tier)

**Steps:**

1. **Create Railway Account**
- Go to https://railway.app
- Sign up with GitHub

2. **Deploy from GitHub**
```bash
# Same git setup as above
git push origin main
```

3. **Create New Project**
- Click "New Project"
- Select "Deploy from GitHub repo"
- Choose your repository

4. **Add PostgreSQL**
- Click "New" → "Database" → "Add PostgreSQL"
- Railway automatically sets `DATABASE_URL`

5. **Add Environment Variables**
```
NODE_ENV=production
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
```

6. **Configure Build**
- Railway auto-detects Node.js
- Add start script in package.json: `"start": "node dist/server.js"`
- Build command: `npm run build && npx prisma generate && npx prisma migrate deploy`

7. **Deploy**
- Railway automatically deploys
- Your app will be live at: `https://helpdesk-mini.up.railway.app`

---

### Option 3: Vercel (For Serverless)

**Note:** Requires restructuring to serverless functions

**Steps:**

1. **Install Vercel CLI**
```bash
npm install -g vercel
```

2. **Login**
```bash
vercel login
```

3. **Deploy**
```bash
vercel
```

4. **Follow prompts**
- Select project directory
- Configure environment variables
- Deploy

---

### Option 4: Heroku (Paid)

**Steps:**

1. **Install Heroku CLI**
```bash
# Download from https://devcli.heroku.com/install
```

2. **Login**
```bash
heroku login
```

3. **Create App**
```bash
heroku create helpdesk-mini
```

4. **Add PostgreSQL**
```bash
heroku addons:create heroku-postgresql:mini
```

5. **Set Environment Variables**
```bash
heroku config:set NODE_ENV=production
heroku config:set JWT_SECRET=your-secret-key
heroku config:set JWT_EXPIRES_IN=7d
```

6. **Deploy**
```bash
git push heroku main
```

7. **Run Migrations**
```bash
heroku run npx prisma migrate deploy
heroku run npm run seed
```

---

## 📝 Pre-Deployment Checklist

### 1. Update Database for Production

**If using PostgreSQL:**

Edit `prisma/schema.prisma`:
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

Run migration:
```bash
npx prisma migrate dev --name switch_to_postgresql
```

### 2. Add Production Scripts

Edit `package.json`:
```json
{
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "migrate": "npx prisma migrate deploy",
    "seed": "tsx src/seed.ts",
    "postinstall": "npx prisma generate"
  }
}
```

### 3. Create `.env.example`

```bash
NODE_ENV=production
DATABASE_URL=your_database_url_here
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRES_IN=7d
PORT=3000
CORS_ORIGIN=*
```

### 4. Update `.gitignore`

```
node_modules/
.env
dist/
*.db
*.db-journal
.DS_Store
```

### 5. Create `Procfile` (for Heroku)

```
web: npm run start
```

### 6. Test Production Build Locally

```bash
npm run build
node dist/server.js
```

---

## 🔒 Security Checklist

- ✅ JWT secret is strong and unique
- ✅ Passwords are hashed with bcrypt
- ✅ Rate limiting is enabled
- ✅ CORS is configured properly
- ✅ Environment variables are not committed
- ✅ SQL injection protected (using Prisma ORM)
- ✅ Input validation on all endpoints

---

## 🧪 Post-Deployment Testing

### 1. Test Health Endpoint
```bash
curl https://your-app.com/api/health
```

Expected: `{"status": "ok", "timestamp": "..."}`

### 2. Test Hackathon Manifest
```bash
curl https://your-app.com/.well-known/hackathon.json
```

Expected: JSON with problem number, endpoints, features

### 3. Test Registration
```bash
curl -X POST https://your-app.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"test123"}'
```

### 4. Test Login
```bash
curl -X POST https://your-app.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### 5. Test Ticket Creation
```bash
curl -X POST https://your-app.com/api/tickets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Idempotency-Key: test-key-123" \
  -d '{"title":"Test Ticket","description":"Test description","priority":"MEDIUM"}'
```

### 6. Test Pagination
```bash
curl "https://your-app.com/api/tickets?limit=5&offset=0" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📊 Monitoring

### Check Logs

**Render:**
```bash
# View in dashboard: Logs tab
```

**Railway:**
```bash
railway logs
```

**Heroku:**
```bash
heroku logs --tail
```

### Monitor Performance

- Response times
- Error rates
- Database queries
- Rate limit hits

---

## 🎯 Hackathon Submission

### What to Submit:

1. **Live URL**: `https://your-app.com`
2. **GitHub Repository**: `https://github.com/YOUR_USERNAME/helpdesk-mini`
3. **API Documentation**: Link to README.md
4. **Test Credentials**:
   - Admin: `admin@helpdesk.com` / `admin123`
   - Agent: `agent1@helpdesk.com` / `agent123`
   - User: `user1@example.com` / `user123`

### Key URLs to Highlight:

- Main UI: `https://your-app.com/`
- API Health: `https://your-app.com/api/health`
- Manifest: `https://your-app.com/.well-known/hackathon.json`
- API Docs: Link to README.md in GitHub

---

## 🆘 Troubleshooting

### Issue: Database connection error

**Solution:**
```bash
# Check DATABASE_URL is set correctly
# Ensure migrations are deployed
npx prisma migrate deploy
```

### Issue: Port already in use

**Solution:**
```bash
# Render/Railway/Heroku manage ports automatically
# Ensure you're using process.env.PORT
```

### Issue: JWT errors

**Solution:**
```bash
# Ensure JWT_SECRET is set
# Check token expiration settings
```

### Issue: CORS errors

**Solution:**
```bash
# Update CORS_ORIGIN environment variable
# Or set to '*' for testing
```

---

## 🎉 Success Checklist

After deployment, verify:

- ✅ UI loads at root URL
- ✅ All API endpoints respond
- ✅ Registration works
- ✅ Login returns JWT token
- ✅ Tickets can be created
- ✅ Comments can be added
- ✅ Pagination works
- ✅ Rate limiting triggers at 60 req/min
- ✅ Idempotency prevents duplicates
- ✅ Error format is consistent
- ✅ SLA tracking works
- ✅ Role-based access enforced

---

## 📞 Support

If you encounter issues:

1. Check the logs (see Monitoring section)
2. Verify environment variables
3. Test locally first with `npm run build && npm start`
4. Check database connectivity
5. Verify all migrations are applied

---

**Good luck with your hackathon submission! 🚀**
