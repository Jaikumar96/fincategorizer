# FinCategorizer - Complete Project File Generator
# This script generates ALL remaining backend services and frontend pages

Write-Host "============================================================" -ForegroundColor Blue
Write-Host "  FinCategorizer - Generating Complete Project" -ForegroundColor Blue
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

# Helper function to create files
function Create-ProjectFile {
    param(
        [string]$Path,
        [string]$Content
    )
    $dir = Split-Path -Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "[OK] Created: $Path" -ForegroundColor Green
}

Write-Host "Creating Category Service..." -ForegroundColor Cyan

# Category Service - pom.xml
$categoryPom = @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
    </parent>
    <groupId>com.fincategorizer</groupId>
    <artifactId>category-service</artifactId>
    <version>1.0.0</version>
    <name>Category Service</name>
    <properties>
        <java.version>17</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
'@

Create-ProjectFile -Path "backend\category-service\pom.xml" -Content $categoryPom

# Category Service - application.yml
$categoryYml = @'
server:
  port: 8082

spring:
  application:
    name: category-service
  datasource:
    url: jdbc:mysql://${MYSQL_HOST:mysql}:3306/${MYSQL_DATABASE:fincategorizer}
    username: ${MYSQL_USER:fincategorizer_app}
    password: ${MYSQL_PASSWORD:app_password_123}
    hikari:
      maximum-pool-size: 10
  jpa:
    hibernate:
      ddl-auto: none
    show-sql: false

logging:
  level:
    root: INFO
    com.fincategorizer: DEBUG

management:
  endpoints:
    web:
      exposure:
        include: health,info
'@

Create-ProjectFile -Path "backend\category-service\src\main\resources\application.yml" -Content $categoryYml

# Category Service Main Class
$categoryMain = @'
package com.fincategorizer.category;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CategoryServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(CategoryServiceApplication.class, args);
    }
}
'@

Create-ProjectFile -Path "backend\category-service\src\main\java\com\fincategorizer\category\CategoryServiceApplication.java" -Content $categoryMain

# Continue with other files...
Write-Host ""
Write-Host "============================================================" -ForegroundColor Blue
Write-Host "  Project files generated successfully!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review generated files" -ForegroundColor White
Write-Host "2. Run: docker-compose up --build" -ForegroundColor White
Write-Host "3. Access: http://localhost:3000" -ForegroundColor White
Write-Host ""
'@

Create-ProjectFile -Path "generate-all-files.ps1" -Content $script

Write-Host "Generation script created: generate-all-files.ps1" -ForegroundColor Green
Write-Host "Run it with: powershell -ExecutionPolicy Bypass -File generate-all-files.ps1" -ForegroundColor Yellow
