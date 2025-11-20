@echo off
REM FinCategorizer - Complete Project Generator for Windows

echo ============================================================
echo   FinCategorizer - Generating Complete Project Files
echo ============================================================
echo.

REM Create Category Service files
mkdir "backend\category-service\src\main\java\com\fincategorizer\category" 2>nul
mkdir "backend\category-service\src\main\java\com\fincategorizer\category\controller" 2>nul
mkdir "backend\category-service\src\main\java\com\fincategorizer\category\service" 2>nul
mkdir "backend\category-service\src\main\java\com\fincategorizer\category\repository" 2>nul
mkdir "backend\category-service\src\main\java\com\fincategorizer\category\entity" 2>nul
mkdir "backend\category-service\src\main\resources" 2>nul

REM Create Analytics Service files
mkdir "backend\analytics-service\src\main\java\com\fincategorizer\analytics" 2>nul
mkdir "backend\analytics-service\src\main\java\com\fincategorizer\analytics\controller" 2>nul
mkdir "backend\analytics-service\src\main\java\com\fincategorizer\analytics\service" 2>nul
mkdir "backend\analytics-service\src\main\java\com\fincategorizer\analytics\repository" 2>nul
mkdir "backend\analytics-service\src\main\resources" 2>nul

REM Create Frontend Pages
mkdir "frontend\src\pages" 2>nul
mkdir "frontend\src\components" 2>nul

echo [OK] Directory structure created
echo.
echo Next steps:
echo 1. Run generate-complete-services.bat to create all service files
echo 2. Run setup.bat to start the application with Docker
echo.

pause
