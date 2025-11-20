package com.fincategorizer.transaction.service;

import com.fincategorizer.transaction.dto.MLCategorizationRequest;
import com.fincategorizer.transaction.dto.MLCategorizationResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class MLInferenceService {
    
    private final WebClient.Builder webClientBuilder;
    private final JdbcTemplate jdbcTemplate;
    
    @Value("${ml-service.url}")
    private String mlServiceUrl;
    
    @Value("${ml-service.timeout:5000}")
    private long timeout;
    
    public MLCategorizationResponse categorize(MLCategorizationRequest request) {
        log.debug("Calling ML service for merchant: {}", request.getMerchantName());
        
        try {
            WebClient webClient = webClientBuilder.baseUrl(mlServiceUrl).build();
            
            MLCategorizationResponse response = webClient.post()
                .uri("/categorize")
                .bodyValue(request)
                .retrieve()
                .bodyToMono(MLCategorizationResponse.class)
                .timeout(Duration.ofMillis(timeout))
                .block();
            
            log.debug("ML service response: category={}, confidence={}",
                response.getCategoryId(), response.getConfidenceScore());
            
            return response;
            
        } catch (Exception e) {
            log.error("Error calling ML service", e);
            // Fallback to "Others" category (category_id = 15)
            return MLCategorizationResponse.builder()
                .categoryId(15)
                .categoryName("Others")
                .confidenceScore(0.5)
                .build();
        }
    }
    
    public void recordUserCorrection(Long transactionId, Long originalCategoryId, 
                                     Long correctedCategoryId, Long userId) {
        String sql = "INSERT INTO model_training_data " +
                    "(transaction_id, original_category_id, corrected_category_id, user_id, correction_date, is_processed) " +
                    "VALUES (?, ?, ?, ?, ?, ?)";
        
        try {
            jdbcTemplate.update(sql, transactionId, originalCategoryId, 
                correctedCategoryId, userId, LocalDateTime.now(), false);
            log.info("Recorded user correction for transaction {}", transactionId);
        } catch (Exception e) {
            log.error("Error recording user correction", e);
        }
    }
}
