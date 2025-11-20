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
public class MLCategorizationRequest {
    
    private String merchantName;
    private Double amount;
    private String currency;
    private List<Integer> recentCategoryIds;
}
