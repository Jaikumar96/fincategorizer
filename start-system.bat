@echo off
echo ========================================
echo FinCategorizer - Complete System Startup
echo ========================================
echo.
echo This script will start the entire FinCategorizer system
echo.
echo Services that will start:
echo - MySQL Database (Port 3306)
echo - Redis Cache (Port 6379)
echo - ML Inference Service (Port 8000)
echo - Transaction Service (Port 8081)
echo - Category Service (Port 8082)
echo - Analytics Service (Port 8083)
echo - API Gateway (Port 8080)
echo - Frontend (Port 3000)
echo.
echo ========================================
echo.

echo [Step 1] Checking if Docker is running...
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running. Please start Docker Desktop.
    pause
    exit /b 1
)
echo OK: Docker is running
echo.

echo [Step 2] Stopping any existing containers...
docker-compose down >nul 2>&1
echo OK: Cleanup complete
echo.

echo [Step 3] Building and starting all services...
echo (This may take 5-10 minutes on first run)
echo.
docker-compose up --build -d
echo.

echo [Step 4] Waiting for services to start (60 seconds)...
timeout /t 60 /nobreak >nul
echo.

echo [Step 5] Checking service health...
echo.
docker-compose ps
echo.

echo ========================================
echo Startup Complete!
echo ========================================
echo.
echo Access your application:
echo.
echo   Frontend:        http://localhost:3000
echo   API Gateway:     http://localhost:8080
echo   ML Service Docs: http://localhost:8000/docs
echo.
echo Demo Login Credentials:
echo   Email:    demo@fincategorizer.com
echo   Password: Demo@123
echo.
echo ========================================
echo.
echo To view logs: docker-compose logs -f [service-name]
echo To stop: docker-compose down
echo.
echo Next steps:
echo 1. Open http://localhost:3000 in your browser
echo 2. Login with demo credentials
echo 3. Upload a CSV file (use Upload page)
echo 4. View analytics and charts
echo.
pause
