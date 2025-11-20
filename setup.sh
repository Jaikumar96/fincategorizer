#!/bin/bash

##############################################################################
# FinCategorizer - Quick Setup Script
# 
# This script sets up the entire FinCategorizer application with one command
# Prerequisites: Docker, Docker Compose installed
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_success "Docker is installed"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    print_success "Docker Compose is installed"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    print_success "Docker daemon is running"
}

# Generate environment file
generate_env_file() {
    print_header "Generating Environment Configuration"
    
    if [ -f .env ]; then
        print_warning ".env file already exists. Backing up to .env.backup"
        cp .env .env.backup
    fi
    
    # Generate strong JWT secret
    JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
    
    cat > .env << EOF
# FinCategorizer Environment Configuration
# Generated on $(date)

# Database
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DATABASE=fincategorizer
MYSQL_USER=fincategorizer_app
MYSQL_PASSWORD=app_password_123
MYSQL_ROOT_PASSWORD=root123

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=604800000

# OAuth 2.0 (Google) - Replace with your credentials
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Frontend
FRONTEND_URL=http://localhost:3000
REACT_APP_API_URL=http://localhost:8080

# Service URLs (Internal)
TRANSACTION_SERVICE_HOST=transaction-service
TRANSACTION_SERVICE_PORT=8081
ML_SERVICE_HOST=ml-inference-service
ML_SERVICE_PORT=8000
CATEGORY_SERVICE_HOST=category-service
CATEGORY_SERVICE_PORT=8082
ANALYTICS_SERVICE_HOST=analytics-service
ANALYTICS_SERVICE_PORT=8083

# Logging
LOG_LEVEL=INFO
EOF
    
    print_success "Environment file created (.env)"
    print_warning "Please update GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in .env file for OAuth"
}

# Build and start services
start_services() {
    print_header "Building and Starting Services"
    
    print_info "This may take 5-10 minutes on first run..."
    
    # Pull base images
    print_info "Pulling base Docker images..."
    docker-compose pull mysql redis || true
    
    # Build custom images
    print_info "Building application images..."
    docker-compose build --parallel
    
    # Start services
    print_info "Starting services..."
    docker-compose up -d
    
    print_success "Services started successfully"
}

# Wait for services to be healthy
wait_for_services() {
    print_header "Waiting for Services to be Ready"
    
    local max_wait=300  # 5 minutes
    local elapsed=0
    
    print_info "Waiting for MySQL to be ready..."
    until docker-compose exec -T mysql mysqladmin ping -h localhost -uroot -proot123 &> /dev/null || [ $elapsed -eq $max_wait ]; do
        sleep 5
        elapsed=$((elapsed + 5))
        echo -n "."
    done
    echo ""
    
    if [ $elapsed -eq $max_wait ]; then
        print_error "MySQL failed to start within ${max_wait} seconds"
        docker-compose logs mysql
        exit 1
    fi
    print_success "MySQL is ready"
    
    print_info "Waiting for Redis to be ready..."
    until docker-compose exec -T redis redis-cli ping &> /dev/null || [ $elapsed -eq $max_wait ]; do
        sleep 2
        elapsed=$((elapsed + 2))
        echo -n "."
    done
    echo ""
    print_success "Redis is ready"
    
    print_info "Waiting for ML Service to be ready..."
    elapsed=0
    until curl -f http://localhost:8000/health &> /dev/null || [ $elapsed -eq $max_wait ]; do
        sleep 5
        elapsed=$((elapsed + 5))
        echo -n "."
    done
    echo ""
    
    if [ $elapsed -eq $max_wait ]; then
        print_warning "ML Service took longer than expected. Check logs with: docker-compose logs ml-inference-service"
    else
        print_success "ML Service is ready"
    fi
    
    print_info "Waiting for API Gateway to be ready..."
    elapsed=0
    until curl -f http://localhost:8080/actuator/health &> /dev/null || [ $elapsed -eq $max_wait ]; do
        sleep 5
        elapsed=$((elapsed + 5))
        echo -n "."
    done
    echo ""
    
    if [ $elapsed -eq $max_wait ]; then
        print_warning "API Gateway took longer than expected. Check logs with: docker-compose logs gateway-service"
    else
        print_success "API Gateway is ready"
    fi
}

# Show service status
show_status() {
    print_header "Service Status"
    docker-compose ps
}

# Show access information
show_access_info() {
    print_header "Access Information"
    
    echo ""
    print_success "FinCategorizer is now running!"
    echo ""
    echo -e "${GREEN}Access Points:${NC}"
    echo -e "  ${BLUE}Frontend:${NC}           http://localhost:3000"
    echo -e "  ${BLUE}API Gateway:${NC}        http://localhost:8080"
    echo -e "  ${BLUE}ML Service:${NC}         http://localhost:8000"
    echo -e "  ${BLUE}API Docs:${NC}           http://localhost:8000/docs"
    echo ""
    echo -e "${GREEN}Demo Credentials:${NC}"
    echo -e "  ${BLUE}Email:${NC}              demo@fincategorizer.com"
    echo -e "  ${BLUE}Password:${NC}           Demo@123"
    echo ""
    echo -e "${GREEN}Useful Commands:${NC}"
    echo -e "  ${BLUE}View logs:${NC}          docker-compose logs -f"
    echo -e "  ${BLUE}Stop services:${NC}      docker-compose down"
    echo -e "  ${BLUE}Restart services:${NC}   docker-compose restart"
    echo -e "  ${BLUE}View status:${NC}        docker-compose ps"
    echo ""
    echo -e "${YELLOW}Note:${NC} Services may take 1-2 minutes to fully initialize."
    echo -e "${YELLOW}Note:${NC} Check logs if any service is not responding: docker-compose logs <service-name>"
    echo ""
}

# Main setup flow
main() {
    clear
    
    print_header "FinCategorizer - Automated Setup"
    echo ""
    print_info "This script will set up the complete FinCategorizer application"
    print_info "including MySQL, Redis, microservices, and React frontend."
    echo ""
    
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    
    check_prerequisites
    generate_env_file
    start_services
    wait_for_services
    show_status
    show_access_info
    
    print_success "Setup completed successfully!"
}

# Cleanup function (optional)
cleanup() {
    print_header "Cleaning Up"
    print_warning "This will remove all containers, volumes, and data!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" == "yes" ]; then
        docker-compose down -v
        print_success "Cleanup completed"
    else
        print_info "Cleanup cancelled"
    fi
}

# Parse command line arguments
case "${1:-}" in
    cleanup|clean)
        cleanup
        ;;
    *)
        main
        ;;
esac
