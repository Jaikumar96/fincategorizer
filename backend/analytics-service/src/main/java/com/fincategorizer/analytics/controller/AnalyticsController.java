package com.fincategorizer.analytics.controller;

import com.fincategorizer.analytics.dto.AccuracyResponse;
import com.fincategorizer.analytics.dto.CategoryDistributionResponse;
import com.fincategorizer.analytics.dto.TrendsResponse;
import com.fincategorizer.analytics.service.AnalyticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
@Slf4j
public class AnalyticsController {
    
    private final AnalyticsService analyticsService;
    
    @GetMapping("/accuracy")
    public ResponseEntity<AccuracyResponse> getAccuracy(
            @RequestHeader("X-User-Id") Long userId) {
        log.info("GET /api/analytics/accuracy - userId: {}", userId);
        AccuracyResponse response = analyticsService.getAccuracy(userId);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/category-distribution")
    public ResponseEntity<CategoryDistributionResponse> getCategoryDistribution(
            @RequestHeader("X-User-Id") Long userId) {
        log.info("GET /api/analytics/category-distribution - userId: {}", userId);
        CategoryDistributionResponse response = analyticsService.getCategoryDistribution(userId);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/trends")
    public ResponseEntity<TrendsResponse> getTrends(
            @RequestHeader("X-User-Id") Long userId,
            @RequestParam(defaultValue = "30") Integer days) {
        log.info("GET /api/analytics/trends - userId: {}, days: {}", userId, days);
        TrendsResponse response = analyticsService.getTrends(userId, days);
        return ResponseEntity.ok(response);
    }
}
