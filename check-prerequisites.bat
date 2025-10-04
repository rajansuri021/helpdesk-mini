@echo off
echo ========================================
echo HelpDesk Mini - Prerequisites Check
echo ========================================
echo.

echo Checking Node.js...
node --version
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed!
    echo Please install Node.js 18+ from https://nodejs.org
    pause
    exit /b 1
)
echo [OK] Node.js is installed
echo.

echo Checking npm...
npm --version
if %errorlevel% neq 0 (
    echo [ERROR] npm is not available!
    pause
    exit /b 1
)
echo [OK] npm is available
echo.

echo Checking PostgreSQL...
psql --version
if %errorlevel% neq 0 (
    echo [WARNING] PostgreSQL CLI not found in PATH
    echo Make sure PostgreSQL is installed and running
) else (
    echo [OK] PostgreSQL CLI is available
)
echo.

echo Checking Redis...
redis-cli --version
if %errorlevel% neq 0 (
    echo [WARNING] Redis CLI not found in PATH
    echo Make sure Redis is installed and running
) else (
    echo [OK] Redis CLI is available
)
echo.

echo ========================================
echo Starting PostgreSQL via Docker (if needed)
echo ========================================
docker ps | findstr helpdesk-postgres
if %errorlevel% neq 0 (
    echo PostgreSQL container not running. Starting...
    docker run --name helpdesk-postgres -e POSTGRES_PASSWORD=helpdesk123 -e POSTGRES_USER=helpdesk -e POSTGRES_DB=helpdesk_db -p 5432:5432 -d postgres:14
    if %errorlevel% neq 0 (
        echo [WARNING] Failed to start PostgreSQL container
        echo Please start PostgreSQL manually
    ) else (
        echo [OK] PostgreSQL container started
        timeout /t 5 /nobreak
    )
) else (
    echo [OK] PostgreSQL container is already running
)
echo.

echo ========================================
echo Starting Redis via Docker (if needed)
echo ========================================
docker ps | findstr helpdesk-redis
if %errorlevel% neq 0 (
    echo Redis container not running. Starting...
    docker run --name helpdesk-redis -p 6379:6379 -d redis:7
    if %errorlevel% neq 0 (
        echo [WARNING] Failed to start Redis container
        echo Please start Redis manually
    ) else (
        echo [OK] Redis container started
        timeout /t 3 /nobreak
    )
) else (
    echo [OK] Redis container is already running
)
echo.

echo ========================================
echo Testing Database Connection
echo ========================================
docker exec helpdesk-postgres psql -U helpdesk -d helpdesk_db -c "SELECT 1;"
if %errorlevel% neq 0 (
    echo [WARNING] Could not connect to database
) else (
    echo [OK] Database connection successful
)
echo.

echo ========================================
echo Testing Redis Connection
echo ========================================
docker exec helpdesk-redis redis-cli ping
if %errorlevel% neq 0 (
    echo [WARNING] Could not connect to Redis
) else (
    echo [OK] Redis connection successful
)
echo.

echo ========================================
echo All Prerequisites Checked!
echo ========================================
echo.
echo Next steps:
echo 1. Run: npm install (if not done)
echo 2. Run: npm run prisma:generate
echo 3. Run: npm run prisma:migrate
echo 4. Run: npm run seed
echo 5. Run: npm run dev
echo.
pause
