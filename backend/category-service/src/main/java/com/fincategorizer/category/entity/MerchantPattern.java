package com.fincategorizer.category.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "merchant_patterns", indexes = {
    @Index(name = "idx_merchant_pattern_region", columnList = "merchant_pattern,region")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MerchantPattern {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "pattern_id")
    private Long patternId;
    
    @Column(name = "merchant_pattern", nullable = false, length = 255)
    private String merchantPattern;
    
    @Column(name = "category_id", nullable = false)
    private Long categoryId;
    
    @Column(length = 10)
    private String region;
    
    @Column
    private Double confidence;
    
    @Column(name = "usage_count")
    private Integer usageCount;
    
    @Column(name = "last_used")
    private LocalDateTime lastUsed;
}
