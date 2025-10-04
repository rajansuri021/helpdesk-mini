#!/bin/bash

echo "🚀 Preparing HelpDesk Mini for Deployment..."
echo ""

# Step 1: Regenerate Prisma for PostgreSQL
echo "📦 Step 1: Generating Prisma Client for PostgreSQL..."
npx prisma generate

# Step 2: Initialize git if not already done
if [ ! -d ".git" ]; then
  echo "🔧 Step 2: Initializing Git repository..."
  git init
  git add .
  git commit -m "Initial commit - HelpDesk Mini"
else
  echo "✅ Git repository already initialized"
fi

echo ""
echo "✅ Preparation Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Create a GitHub repository"
echo "2. Run: git remote add origin YOUR_GITHUB_REPO_URL"
echo "3. Run: git push -u origin main"
echo "4. Go to https://render.com and sign up"
echo "5. Follow the steps in FREE_HOSTING.md"
echo ""
echo "🎉 Your app will be live in ~15 minutes!"
