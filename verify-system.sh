#!/bin/bash

# FinCategorizer - System Verification Script
# This script verifies that all services are running correctly

echo "========================================"
echo "FinCategorizer System Verification"
echo "========================================"
echo ""

echo "[1/8] Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not found. Please install Docker."
    exit 1
fi
echo "OK: Docker is installed"

echo ""
echo "[2/8] Checking Docker Compose installation..."
if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose not found."
    exit 1
fi
echo "OK: Docker Compose is installed"

echo ""
echo "[3/8] Checking if services are running..."
if ! docker-compose ps &> /dev/null; then
    echo "WARNING: Services are not running."
    read -p "Would you like to start them now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting services..."
        docker-compose up -d
        echo ""
        echo "Waiting for services to start (60 seconds)..."
        sleep 60
    else
        echo "Please run: docker-compose up -d"
        exit 1
    fi
fi
echo "OK: Docker Compose is running"

echo ""
echo "[4/8] Checking MySQL (Port 3306)..."
if nc -z localhost 3306 2>/dev/null; then
    echo "OK: MySQL port is accessible"
else
    echo "WARNING: MySQL port 3306 not accessible"
fi

echo ""
echo "[5/8] Checking Redis (Port 6379)..."
if nc -z localhost 6379 2>/dev/null; then
    echo "OK: Redis port is accessible"
else
    echo "WARNING: Redis port 6379 not accessible"
fi

echo ""
echo "[6/8] Checking ML Service (Port 8000)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
if [ "$HTTP_CODE" == "200" ]; then
    echo "OK: ML Service is healthy"
else
    echo "ERROR: ML Service not responding (HTTP $HTTP_CODE)"
    echo "Check logs: docker-compose logs ml-inference-service"
fi

echo ""
echo "[7/8] Checking Gateway (Port 8080)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health)
if [ "$HTTP_CODE" == "200" ]; then
    echo "OK: Gateway is healthy"
else
    echo "ERROR: Gateway not responding (HTTP $HTTP_CODE)"
    echo "Check logs: docker-compose logs gateway-service"
fi

echo ""
echo "[8/8] Checking Frontend (Port 3000)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$HTTP_CODE" == "200" ]; then
    echo "OK: Frontend is accessible"
else
    echo "ERROR: Frontend not responding (HTTP $HTTP_CODE)"
    echo "Check logs: docker-compose logs frontend"
fi

echo ""
echo "========================================"
echo "Service Status Summary"
echo "========================================"
docker-compose ps

echo ""
echo "========================================"
echo "Access Points"
echo "========================================"
echo "Frontend:        http://localhost:3000"
echo "API Gateway:     http://localhost:8080"
echo "ML Service Docs: http://localhost:8000/docs"
echo ""
echo "Demo Login:"
echo "  Email:    demo@fincategorizer.com"
echo "  Password: Demo@123"
echo "========================================"

echo ""
echo "Verification complete!"
echo ""
echo "Next steps:"
echo "1. Open http://localhost:3000 in your browser"
echo "2. Login with demo credentials"
echo "3. Try uploading a CSV file"
echo "4. View analytics charts"
echo ""
