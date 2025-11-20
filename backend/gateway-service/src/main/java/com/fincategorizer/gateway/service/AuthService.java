package com.fincategorizer.gateway.service;

import com.fincategorizer.gateway.dto.LoginRequest;
import com.fincategorizer.gateway.dto.LoginResponse;
import com.fincategorizer.gateway.dto.RegisterRequest;
import com.fincategorizer.gateway.entity.User;
import com.fincategorizer.gateway.repository.UserRepository;
import com.fincategorizer.gateway.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Transactional
    public Mono<LoginResponse> login(LoginRequest request) {
        return Mono.fromCallable(() -> {
            log.debug("Attempting login for email: {}", request.getEmail());
            
            User user = userRepository.findByEmail(request.getEmail())
                    .orElseThrow(() -> new RuntimeException("Invalid credentials"));
            
            if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                throw new RuntimeException("Invalid credentials");
            }
            
            String token = jwtUtil.generateToken(user.getEmail(), user.getId());
            String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());
            
            return LoginResponse.builder()
                    .token(token)
                    .refreshToken(refreshToken)
                    .tokenType("Bearer")
                    .expiresIn(3600000L) // 1 hour
                    .user(LoginResponse.UserInfo.builder()
                            .id(user.getId())
                            .email(user.getEmail())
                            .name(user.getName())
                            .build())
                    .build();
        }).subscribeOn(Schedulers.boundedElastic());
    }

    @Transactional
    public Mono<LoginResponse> register(RegisterRequest request) {
        return Mono.fromCallable(() -> {
            log.debug("Attempting registration for email: {}", request.getEmail());
            
            if (userRepository.existsByEmail(request.getEmail())) {
                throw new RuntimeException("Email already exists");
            }
            
            User user = User.builder()
                    .email(request.getEmail())
                    .password(passwordEncoder.encode(request.getPassword()))
                    .name(request.getName())
                    .build();
            
            user = userRepository.save(user);
            
            String token = jwtUtil.generateToken(user.getEmail(), user.getId());
            String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());
            
            return LoginResponse.builder()
                    .token(token)
                    .refreshToken(refreshToken)
                    .tokenType("Bearer")
                    .expiresIn(3600000L)
                    .user(LoginResponse.UserInfo.builder()
                            .id(user.getId())
                            .email(user.getEmail())
                            .name(user.getName())
                            .build())
                    .build();
        }).subscribeOn(Schedulers.boundedElastic());
    }

    public Mono<LoginResponse.UserInfo> getCurrentUser(String token) {
        return Mono.fromCallable(() -> {
            String email = jwtUtil.extractUsername(token);
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            
            return LoginResponse.UserInfo.builder()
                    .id(user.getId())
                    .email(user.getEmail())
                    .name(user.getName())
                    .build();
        }).subscribeOn(Schedulers.boundedElastic());
    }
}
