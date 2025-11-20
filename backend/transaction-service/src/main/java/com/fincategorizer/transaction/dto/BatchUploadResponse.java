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
public class BatchUploadResponse {
    
    private Integer totalRecords;
    private Integer successCount;
    private Integer failureCount;
    private List<ErrorDetail> errors;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ErrorDetail {
        private Integer rowNumber;
        private String merchantName;
        private String error;
    }
}
