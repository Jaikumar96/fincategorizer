package com.fincategorizer.transaction.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MLCategorizationResponse {
    
    private Integer categoryId;
    private String categoryName;
    private Double confidenceScore;
    private List<AlternativeCategory> alternatives;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AlternativeCategory {
        private Integer categoryId;
        private String categoryName;
        private Double confidence;
    }
}
