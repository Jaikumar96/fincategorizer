package com.fincategorizer.gateway.filter;

import com.fincategorizer.gateway.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;

@Component
public class AddUserIdHeaderFilter extends AbstractGatewayFilterFactory<Object> {

    private final JwtUtil jwtUtil;

    @Autowired
    public AddUserIdHeaderFilter(JwtUtil jwtUtil) {
        super(Object.class);
        this.jwtUtil = jwtUtil;
    }

    @Override
    public GatewayFilter apply(Object config) {
        return (exchange, chain) -> {
            String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
            
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                try {
                    String token = authHeader.substring(7);
                    Long userId = jwtUtil.extractUserId(token);
                    
                    if (userId != null) {
                        ServerWebExchange modifiedExchange = exchange.mutate()
                                .request(r -> r.header("X-User-Id", String.valueOf(userId)))
                                .build();
                        
                        return chain.filter(modifiedExchange);
                    }
                } catch (Exception e) {
                    // Continue without X-User-Id header if extraction fails
                }
            }
            
            return chain.filter(exchange);
        };
    }
}
