# 🚀 Free Hosting Guide for HelpDesk Mini

## Option 1: Render.com (Recommended)

### Steps to Deploy:

1. **Push your code to GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin YOUR_GITHUB_REPO_URL
   git push -u origin main
   ```

2. **Sign up at Render.com:**
   - Go to https://render.com
   - Sign up with your GitHub account (free)

3. **Create PostgreSQL Database:**
   - Click "New +" → "PostgreSQL"
   - Name: `helpdesk-db`
   - Select Free tier
   - Click "Create Database"
   - Copy the "Internal Database URL"

4. **Create Web Service:**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Settings:
     - **Name**: helpdesk-mini
     - **Environment**: Node
     - **Build Command**: `npm install && npx prisma generate && npx prisma migrate deploy && npm run build`
     - **Start Command**: `npm start`
     - **Plan**: Free

5. **Add Environment Variables:**
   - `DATABASE_URL` = (paste the Internal Database URL from step 3)
   - `JWT_SECRET` = (generate a random string like `your-super-secret-jwt-key-12345`)
   - `NODE_ENV` = `production`

6. **Deploy:**
   - Click "Create Web Service"
   - Wait 5-10 minutes for deployment
   - Your app will be live at: `https://helpdesk-mini.onrender.com`

---

## Option 2: Railway.app

### Steps:

1. **Push to GitHub** (same as above)

2. **Sign up at Railway.app:**
   - Go to https://railway.app
   - Sign up with GitHub (free)

3. **Deploy:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository
   - Railway will auto-detect Node.js

4. **Add PostgreSQL:**
   - Click "+ New"
   - Select "Database" → "PostgreSQL"
   - Railway auto-links it to your app

5. **Add Environment Variables:**
   - Go to your service → Variables
   - Add:
     - `JWT_SECRET` = `your-secret-key`
     - `NODE_ENV` = `production`
   - `DATABASE_URL` is auto-added by Railway

6. **Deploy:**
   - Railway auto-deploys
   - Get your URL from the service settings

---

## Option 3: Vercel (Frontend) + Neon (Database)

### For Database (Neon.tech):
1. Sign up at https://neon.tech (free PostgreSQL)
2. Create a project
3. Copy the connection string

### For App (Vercel):
1. Sign up at https://vercel.com
2. Import from GitHub
3. Add environment variables
4. Deploy

---

## 📋 Pre-Deployment Checklist:

✅ Changed `schema.prisma` from SQLite to PostgreSQL
✅ Created `.gitignore` file
✅ Have a GitHub account
✅ Code is pushed to GitHub

---

## 🎯 Quick Deploy (Render - 15 minutes):

1. Create GitHub repo and push code
2. Sign up at Render.com
3. Create PostgreSQL database (free tier)
4. Create Web Service linked to your repo
5. Add environment variables (DATABASE_URL, JWT_SECRET)
6. Deploy and wait ~10 minutes
7. Your app is LIVE! 🎉

---

## 💡 Tips:

- **Render Free Tier**: Sleeps after 15 min of inactivity, wakes up in 30 sec
- **Railway Free Tier**: 500 hours/month (enough for testing)
- **Both provide HTTPS** automatically
- **PostgreSQL is required** for production (SQLite doesn't work on these platforms)

---

## 🆘 Need Help?

Check the full deployment guide in `DEPLOYMENT_GUIDE.md` or `QUICK_DEPLOY.md`
