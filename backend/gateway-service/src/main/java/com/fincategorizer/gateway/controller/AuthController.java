package com.fincategorizer.gateway.controller;

import com.fincategorizer.gateway.dto.LoginRequest;
import com.fincategorizer.gateway.dto.LoginResponse;
import com.fincategorizer.gateway.dto.RegisterRequest;
import com.fincategorizer.gateway.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import jakarta.validation.Valid;

/**
 * Authentication Controller
 * Handles user authentication and registration
 */
@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public Mono<ResponseEntity<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        log.info("Login request for email: {}", request.getEmail());
        return authService.login(request)
                .map(ResponseEntity::ok)
                .onErrorResume(e -> {
                    log.error("Login failed for email: {}", request.getEmail(), e);
                    return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build());
                });
    }

    @PostMapping("/register")
    public Mono<ResponseEntity<LoginResponse>> register(@Valid @RequestBody RegisterRequest request) {
        log.info("Registration request for email: {}", request.getEmail());
        return authService.register(request)
                .map(ResponseEntity::ok)
                .onErrorResume(e -> {
                    log.error("Registration failed for email: {}", request.getEmail(), e);
                    return Mono.just(ResponseEntity.badRequest().build());
                });
    }

    @PostMapping("/logout")
    public Mono<ResponseEntity<Void>> logout(@RequestHeader("Authorization") String token) {
        log.info("Logout request");
        return Mono.just(ResponseEntity.ok().build());
    }

    @GetMapping("/me")
    public Mono<ResponseEntity<LoginResponse.UserInfo>> getCurrentUser(@RequestHeader("Authorization") String token) {
        log.info("Get current user request");
        String jwt = token.replace("Bearer ", "");
        return authService.getCurrentUser(jwt)
                .map(ResponseEntity::ok)
                .onErrorResume(e -> {
                    log.error("Failed to get current user", e);
                    return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build());
                });
    }
}
