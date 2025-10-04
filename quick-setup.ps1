# Quick Setup Script for HelpDesk Mini
# This script automates the entire setup process

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HelpDesk Mini - Quick Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prerequisites
Write-Host "Step 1: Checking prerequisites..." -ForegroundColor Yellow
& .\check-prerequisites.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Prerequisites check failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Install dependencies
Write-Host ""
Write-Host "Step 2: Installing dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to install dependencies!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Dependencies installed" -ForegroundColor Green

# Step 3: Generate Prisma client
Write-Host ""
Write-Host "Step 3: Generating Prisma client..." -ForegroundColor Yellow
npm run prisma:generate
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to generate Prisma client!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Prisma client generated" -ForegroundColor Green

# Step 4: Run migrations
Write-Host ""
Write-Host "Step 4: Running database migrations..." -ForegroundColor Yellow
npm run prisma:migrate
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Migration may have issues. Check database connection." -ForegroundColor Yellow
}

# Step 5: Seed database
Write-Host ""
Write-Host "Step 5: Seeding database with test data..." -ForegroundColor Yellow
npm run seed
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Seeding may have issues. Check database connection." -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎉 Your HelpDesk Mini is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "To start the development server:" -ForegroundColor Yellow
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "Then open your browser to:" -ForegroundColor Yellow
Write-Host "  http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "Test Credentials:" -ForegroundColor Yellow
Write-Host "  Admin:  admin@helpdesk.com / admin123" -ForegroundColor White
Write-Host "  Agent:  agent1@helpdesk.com / agent123" -ForegroundColor White
Write-Host "  User:   user1@example.com / user123" -ForegroundColor White
Write-Host ""
Write-Host "API Documentation:" -ForegroundColor Yellow
Write-Host "  README.md - Full documentation" -ForegroundColor White
Write-Host "  API_EXAMPLES.md - Request/response examples" -ForegroundColor White
Write-Host "  SETUP.md - Detailed setup guide" -ForegroundColor White
Write-Host ""
