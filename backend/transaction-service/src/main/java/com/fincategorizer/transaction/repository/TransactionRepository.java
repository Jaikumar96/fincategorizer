package com.fincategorizer.transaction.repository;

import com.fincategorizer.transaction.entity.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    
    Page<Transaction> findByUserId(Long userId, Pageable pageable);
    
    Page<Transaction> findByUserIdAndCategoryId(Long userId, Long categoryId, Pageable pageable);
    
    Page<Transaction> findByUserIdAndTransactionDateBetween(
        Long userId, 
        LocalDate startDate, 
        LocalDate endDate, 
        Pageable pageable
    );
    
    @Query("SELECT t FROM Transaction t WHERE t.userId = :userId " +
           "AND (:categoryId IS NULL OR t.categoryId = :categoryId) " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate)")
    Page<Transaction> findByFilters(
        @Param("userId") Long userId,
        @Param("categoryId") Long categoryId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        Pageable pageable
    );
    
    List<Transaction> findTop5ByUserIdOrderByTransactionDateDesc(Long userId);
    
    @Query("SELECT t FROM Transaction t WHERE t.userId = :userId " +
           "AND t.merchantNormalized = :merchantNormalized " +
           "ORDER BY t.transactionDate DESC LIMIT 5")
    List<Transaction> findRecentByMerchant(
        @Param("userId") Long userId,
        @Param("merchantNormalized") String merchantNormalized
    );
}
