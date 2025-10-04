# Quick Deployment Steps

## 🚀 Deploy to Render.com (15 minutes)

### Step 1: Update for PostgreSQL
```bash
# Edit prisma/schema.prisma - change line 6:
# FROM: provider = "sqlite"
# TO:   provider = "postgresql"
```

### Step 2: Push to GitHub
```bash
git init
git add .
git commit -m "HelpDesk Mini - Hackathon Submission"

# Create repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/helpdesk-mini.git
git branch -M main
git push -u origin main
```

### Step 3: Deploy on Render

1. Go to https://render.com/register
2. Sign up with GitHub
3. Click "New +" → "Web Service"
4. Select "helpdesk-mini" repository
5. Configure:
   ```
   Name: helpdesk-mini
   Environment: Node
   Branch: main
   Build Command: npm install && npx prisma generate && npx prisma migrate deploy
   Start Command: npm start
   ```

### Step 4: Add PostgreSQL

1. In Render dashboard, click "New +" → "PostgreSQL"
2. Name: helpdesk-db
3. Click "Create Database"
4. Copy "Internal Database URL"

### Step 5: Set Environment Variables

In your web service, go to "Environment" tab and add:

```
NODE_ENV=production
DATABASE_URL=<paste Internal Database URL from step 4>
JWT_SECRET=hackathon-super-secret-key-2024-change-this
JWT_EXPIRES_IN=7d
PORT=3000
CORS_ORIGIN=*
```

### Step 6: Deploy

1. Click "Manual Deploy" → "Deploy latest commit"
2. Wait 3-5 minutes for build
3. Your app will be live at: `https://helpdesk-mini.onrender.com`

### Step 7: Seed Database

1. In Render dashboard, click "Shell"
2. Run:
   ```bash
   npm run seed
   ```

### Step 8: Test

1. Visit: `https://helpdesk-mini.onrender.com`
2. Login with: `admin@helpdesk.com` / `admin123`
3. Test all features

---

## ✅ Done! Your app is live!

**Submit these URLs:**
- Live App: `https://helpdesk-mini.onrender.com`
- GitHub: `https://github.com/YOUR_USERNAME/helpdesk-mini`
- API Health: `https://helpdesk-mini.onrender.com/api/health`
- Manifest: `https://helpdesk-mini.onrender.com/.well-known/hackathon.json`

**Test Credentials:**
- Admin: admin@helpdesk.com / admin123
- Agent: agent1@helpdesk.com / agent123
- User: user1@example.com / user123
