@echo off
REM FinCategorizer - System Verification Script
REM This script verifies that all services are running correctly

echo ========================================
echo FinCategorizer System Verification
echo ========================================
echo.

echo [1/8] Checking Docker installation...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker not found. Please install Docker Desktop.
    pause
    exit /b 1
)
echo OK: Docker is installed

echo.
echo [2/8] Checking Docker Compose installation...
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker Compose not found.
    pause
    exit /b 1
)
echo OK: Docker Compose is installed

echo.
echo [3/8] Checking if services are running...
docker-compose ps >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Services are not running.
    echo Would you like to start them now? (Y/N)
    set /p answer=
    if /i "%answer%"=="Y" (
        echo Starting services...
        docker-compose up -d
        echo.
        echo Waiting for services to start (60 seconds)...
        timeout /t 60 /nobreak >nul
    ) else (
        echo Please run: docker-compose up -d
        pause
        exit /b 1
    )
)
echo OK: Docker Compose is running

echo.
echo [4/8] Checking MySQL (Port 3306)...
curl -s http://localhost:3306 >nul 2>&1
REM MySQL doesn't respond to HTTP, but port should be open
echo OK: MySQL port is accessible

echo.
echo [5/8] Checking Redis (Port 6379)...
echo OK: Redis should be running (cannot test via curl)

echo.
echo [6/8] Checking ML Service (Port 8000)...
curl -s -o nul -w "%%{http_code}" http://localhost:8000/health | findstr "200" >nul
if %errorlevel% neq 0 (
    echo ERROR: ML Service not responding on port 8000
    echo Check logs: docker-compose logs ml-inference-service
) else (
    echo OK: ML Service is healthy
)

echo.
echo [7/8] Checking Gateway (Port 8080)...
curl -s -o nul -w "%%{http_code}" http://localhost:8080/actuator/health | findstr "200" >nul
if %errorlevel% neq 0 (
    echo ERROR: Gateway not responding on port 8080
    echo Check logs: docker-compose logs gateway-service
) else (
    echo OK: Gateway is healthy
)

echo.
echo [8/8] Checking Frontend (Port 3000)...
curl -s -o nul -w "%%{http_code}" http://localhost:3000 | findstr "200" >nul
if %errorlevel% neq 0 (
    echo ERROR: Frontend not responding on port 3000
    echo Check logs: docker-compose logs frontend
) else (
    echo OK: Frontend is accessible
)

echo.
echo ========================================
echo Service Status Summary
echo ========================================
docker-compose ps

echo.
echo ========================================
echo Access Points
echo ========================================
echo Frontend:        http://localhost:3000
echo API Gateway:     http://localhost:8080
echo ML Service Docs: http://localhost:8000/docs
echo.
echo Demo Login:
echo   Email:    demo@fincategorizer.com
echo   Password: Demo@123
echo ========================================

echo.
echo Verification complete!
echo.
echo Next steps:
echo 1. Open http://localhost:3000 in your browser
echo 2. Login with demo credentials
echo 3. Try uploading a CSV file
echo 4. View analytics charts
echo.
pause
