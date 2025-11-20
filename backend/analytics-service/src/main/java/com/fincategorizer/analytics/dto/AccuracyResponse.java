package com.fincategorizer.analytics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AccuracyResponse {
    
    private Double overallAccuracy;
    private Integer totalTransactions;
    private Integer correctPredictions;
    private Integer userCorrected;
    private String period;
}
