# PowerShell script to check prerequisites and setup
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HelpDesk Mini - Prerequisites Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Node.js
Write-Host "Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js is installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js is not installed!" -ForegroundColor Red
    Write-Host "Please install Node.js 18+ from https://nodejs.org" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check npm
Write-Host "Checking npm..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version
    Write-Host "[OK] npm is available: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] npm is not available!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check Docker
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "[OK] Docker is installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Docker is not installed" -ForegroundColor Yellow
    Write-Host "You'll need to install PostgreSQL and Redis manually" -ForegroundColor Yellow
}
Write-Host ""

# Start PostgreSQL container
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting PostgreSQL via Docker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$postgresRunning = docker ps --format "{{.Names}}" | Select-String "helpdesk-postgres"
if (-not $postgresRunning) {
    Write-Host "PostgreSQL container not running. Starting..." -ForegroundColor Yellow
    docker run --name helpdesk-postgres -e POSTGRES_PASSWORD=helpdesk123 -e POSTGRES_USER=helpdesk -e POSTGRES_DB=helpdesk_db -p 5432:5432 -d postgres:14
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] PostgreSQL container started" -ForegroundColor Green
        Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    } else {
        # Try to start existing container
        docker start helpdesk-postgres
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Existing PostgreSQL container started" -ForegroundColor Green
            Start-Sleep -Seconds 3
        } else {
            Write-Host "[WARNING] Failed to start PostgreSQL container" -ForegroundColor Yellow
            Write-Host "Please start PostgreSQL manually or check Docker logs" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[OK] PostgreSQL container is already running" -ForegroundColor Green
}
Write-Host ""

# Start Redis container
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Redis via Docker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$redisRunning = docker ps --format "{{.Names}}" | Select-String "helpdesk-redis"
if (-not $redisRunning) {
    Write-Host "Redis container not running. Starting..." -ForegroundColor Yellow
    docker run --name helpdesk-redis -p 6379:6379 -d redis:7
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Redis container started" -ForegroundColor Green
        Start-Sleep -Seconds 3
    } else {
        # Try to start existing container
        docker start helpdesk-redis
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Existing Redis container started" -ForegroundColor Green
            Start-Sleep -Seconds 2
        } else {
            Write-Host "[WARNING] Failed to start Redis container" -ForegroundColor Yellow
            Write-Host "Please start Redis manually or check Docker logs" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[OK] Redis container is already running" -ForegroundColor Green
}
Write-Host ""

# Test connections
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Connections" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Testing PostgreSQL connection..." -ForegroundColor Yellow
try {
    docker exec helpdesk-postgres psql -U helpdesk -d helpdesk_db -c "SELECT 1;" | Out-Null
    Write-Host "[OK] PostgreSQL connection successful" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Could not connect to PostgreSQL" -ForegroundColor Yellow
}

Write-Host "Testing Redis connection..." -ForegroundColor Yellow
try {
    $redisPing = docker exec helpdesk-redis redis-cli ping
    if ($redisPing -eq "PONG") {
        Write-Host "[OK] Redis connection successful" -ForegroundColor Green
    }
} catch {
    Write-Host "[WARNING] Could not connect to Redis" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Prerequisites Check Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: npm install" -ForegroundColor White
Write-Host "2. Run: npm run prisma:generate" -ForegroundColor White
Write-Host "3. Run: npm run prisma:migrate" -ForegroundColor White
Write-Host "4. Run: npm run seed" -ForegroundColor White
Write-Host "5. Run: npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "Or run the automated setup:" -ForegroundColor Yellow
Write-Host ".\quick-setup.ps1" -ForegroundColor White
Write-Host ""
