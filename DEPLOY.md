# 🚀 Deployment Guide (Secure)

## Quick Deploy to Render.com

### Step 1: Push to GitHub ✅ DONE

Your code is already on GitHub at:
https://github.com/rajansuri021/helpdesk-mini

---

### Step 2: Deploy to Render.com

1. **Sign up**: https://render.com (use GitHub login)

2. **Create PostgreSQL Database**:
   - Click "New +" → "PostgreSQL"
   - Name: `helpdesk-db`
   - Plan: **Free**
   - Copy the **Internal Database URL**

3. **Create Web Service**:
   - Click "New +" → "Web Service"
   - Connect: `rajansuri021/helpdesk-mini`
   - Build Command:
     ```
     npm install && npx prisma generate && npx prisma migrate deploy && npm run build
     ```
   - Start Command:
     ```
     npm start
     ```
   - Plan: **Free**

4. **Add Environment Variables**:
   - `DATABASE_URL` = (Internal Database URL from step 2)
   - `JWT_SECRET` = (generate random: `openssl rand -hex 32`)
   - `NODE_ENV` = `production`

5. **Deploy** and wait 5-10 minutes

---

### Step 3: Create Admin Account

After deployment, you'll need to create your admin account securely.

⚠️ **Note**: The seed file creates test accounts. Change passwords immediately after first login!

---

### Security Checklist:

- ✅ Removed credential files from GitHub
- ⚠️ Change default passwords after deployment
- ✅ Use strong JWT_SECRET
- ✅ PostgreSQL for production
- ✅ HTTPS enabled by default

---

Your app will be live at: `https://your-app-name.onrender.com`
