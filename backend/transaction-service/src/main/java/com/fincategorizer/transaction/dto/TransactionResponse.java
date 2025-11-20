package com.fincategorizer.transaction.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionResponse {
    
    private Long transactionId;
    private String merchantName;
    private String merchantNormalized;
    private BigDecimal amount;
    private String currency;
    private LocalDate transactionDate;
    private CategoryResponse category;
    private BigDecimal confidenceScore;
    private Boolean isUserCorrected;
    private LocalDateTime createdAt;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryResponse {
        private Long categoryId;
        private String categoryName;
        private String icon;
        private String color;
    }
}
