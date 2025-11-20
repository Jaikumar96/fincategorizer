package com.fincategorizer.category.repository;

import com.fincategorizer.category.entity.MerchantPattern;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MerchantPatternRepository extends JpaRepository<MerchantPattern, Long> {
    
    List<MerchantPattern> findByRegion(String region);
    
    @Query("SELECT mp FROM MerchantPattern mp WHERE :merchantName LIKE CONCAT('%', mp.merchantPattern, '%') ORDER BY mp.confidence DESC")
    List<MerchantPattern> findMatchingPatterns(@Param("merchantName") String merchantName);
    
    Optional<MerchantPattern> findByMerchantPatternAndRegion(String merchantPattern, String region);
    
    List<MerchantPattern> findByCategoryId(Long categoryId);
}
