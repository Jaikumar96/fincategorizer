@echo off
REM FinCategorizer - Windows Setup Script

echo ============================================================
echo   FinCategorizer - Quick Setup for Windows
echo ============================================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

echo [OK] Docker is installed

REM Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Compose is not installed. Please install Docker Compose first.
    pause
    exit /b 1
)

echo [OK] Docker Compose is installed

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running. Please start Docker Desktop.
    pause
    exit /b 1
)

echo [OK] Docker is running
echo.

REM Build and start services
echo Building and starting services...
echo This may take 5-10 minutes on first run...
echo.

docker-compose up -d --build

if %errorlevel% neq 0 (
    echo [ERROR] Failed to start services
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   Waiting for services to be ready...
echo ============================================================
echo.

REM Wait for MySQL
echo Waiting for MySQL...
timeout /t 30 /nobreak >nul

REM Wait for services
echo Waiting for all services to initialize...
timeout /t 60 /nobreak >nul

echo.
echo ============================================================
echo   FinCategorizer is now running!
echo ============================================================
echo.
echo Access Points:
echo   Frontend:           http://localhost:3000
echo   API Gateway:        http://localhost:8080
echo   ML Service:         http://localhost:8000
echo   API Docs:           http://localhost:8000/docs
echo.
echo Demo Credentials:
echo   Email:              demo@fincategorizer.com
echo   Password:           Demo@123
echo.
echo Useful Commands:
echo   View logs:          docker-compose logs -f
echo   Stop services:      docker-compose down
echo   Restart services:   docker-compose restart
echo   View status:        docker-compose ps
echo.
echo Note: Services may take 1-2 minutes to fully initialize.
echo.

pause
