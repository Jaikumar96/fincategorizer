package com.fincategorizer.transaction.service;

import com.fincategorizer.transaction.dto.*;
import com.fincategorizer.transaction.entity.Category;
import com.fincategorizer.transaction.entity.Transaction;
import com.fincategorizer.transaction.repository.CategoryRepository;
import com.fincategorizer.transaction.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class TransactionService {
    
    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final MLInferenceService mlInferenceService;
    private final CacheService cacheService;
    
    private static final DateTimeFormatter[] DATE_FORMATTERS = {
        DateTimeFormatter.ofPattern("yyyy-MM-dd"),
        DateTimeFormatter.ofPattern("dd/MM/yyyy"),
        DateTimeFormatter.ofPattern("MM/dd/yyyy"),
        DateTimeFormatter.ofPattern("dd-MM-yyyy")
    };
    
    @Transactional
    public TransactionResponse createTransaction(Long userId, TransactionRequest request) {
        log.info("Creating transaction for user: {}, merchant: {}", userId, request.getMerchantName());
        
        // Normalize merchant name
        String normalized = normalizeMerchantName(request.getMerchantName());
        
        // Get recent transactions for context
        List<Transaction> recentTransactions = transactionRepository
            .findTop5ByUserIdOrderByTransactionDateDesc(userId);
        List<Integer> recentCategoryIds = recentTransactions.stream()
            .filter(t -> t.getCategoryId() != null)
            .map(t -> t.getCategoryId().intValue())
            .collect(Collectors.toList());
        
        // Call ML service for categorization
        MLCategorizationResponse mlResponse = mlInferenceService.categorize(
            MLCategorizationRequest.builder()
                .merchantName(normalized)
                .amount(request.getAmount().doubleValue())
                .currency(request.getCurrency())
                .recentCategoryIds(recentCategoryIds)
                .build()
        );
        
        // Create transaction
        Transaction transaction = Transaction.builder()
            .userId(userId)
            .merchantName(request.getMerchantName())
            .merchantNormalized(normalized)
            .amount(request.getAmount())
            .currency(request.getCurrency())
            .transactionDate(request.getTransactionDate())
            .categoryId(mlResponse.getCategoryId().longValue())
            .confidenceScore(BigDecimal.valueOf(mlResponse.getConfidenceScore()))
            .isUserCorrected(false)
            .metadataJson(request.getDescription() != null ? 
                String.format("{\"description\":\"%s\"}", request.getDescription()) : null)
            .build();
        
        transaction = transactionRepository.save(transaction);
        
        // Cache merchant mapping if high confidence
        if (mlResponse.getConfidenceScore() >= 0.85) {
            cacheService.cacheMerchantMapping(normalized, mlResponse.getCategoryId().longValue());
        }
        
        return convertToResponse(transaction);
    }
    
    @Transactional
    public BatchUploadResponse uploadBatch(Long userId, MultipartFile file) {
        log.info("Processing batch upload for user: {}, file: {}", userId, file.getOriginalFilename());
        
        List<BatchUploadResponse.ErrorDetail> errors = new ArrayList<>();
        int successCount = 0;
        int rowNumber = 0;
        
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8));
             CSVParser csvParser = new CSVParser(reader, 
                CSVFormat.DEFAULT.builder()
                    .setHeader()
                    .setSkipHeaderRecord(true)
                    .build())) {
            
            for (CSVRecord record : csvParser) {
                rowNumber++;
                try {
                    TransactionRequest request = parseCSVRecord(record);
                    createTransaction(userId, request);
                    successCount++;
                } catch (Exception e) {
                    log.error("Error processing row {}: {}", rowNumber, e.getMessage());
                    errors.add(BatchUploadResponse.ErrorDetail.builder()
                        .rowNumber(rowNumber)
                        .merchantName(record.get("merchant"))
                        .error(e.getMessage())
                        .build());
                }
            }
            
        } catch (Exception e) {
            log.error("Error parsing CSV file", e);
            throw new RuntimeException("Failed to parse CSV file: " + e.getMessage());
        }
        
        return BatchUploadResponse.builder()
            .totalRecords(rowNumber)
            .successCount(successCount)
            .failureCount(errors.size())
            .errors(errors)
            .build();
    }
    
    @Transactional(readOnly = true)
    public Page<TransactionResponse> getTransactions(
            Long userId, 
            Long categoryId,
            LocalDate startDate,
            LocalDate endDate,
            Pageable pageable) {
        
        Page<Transaction> transactions = transactionRepository.findByFilters(
            userId, categoryId, startDate, endDate, pageable);
        
        return transactions.map(this::convertToResponse);
    }
    
    @Transactional
    public TransactionResponse updateCategory(Long transactionId, Long userId, Long newCategoryId, String reason) {
        Transaction transaction = transactionRepository.findById(transactionId)
            .orElseThrow(() -> new RuntimeException("Transaction not found"));
        
        if (!transaction.getUserId().equals(userId)) {
            throw new RuntimeException("Unauthorized access to transaction");
        }
        
        Long oldCategoryId = transaction.getCategoryId();
        transaction.setCategoryId(newCategoryId);
        transaction.setIsUserCorrected(true);
        transaction = transactionRepository.save(transaction);
        
        // Store correction for self-learning
        mlInferenceService.recordUserCorrection(transactionId, oldCategoryId, newCategoryId, userId);
        
        // Update cache
        cacheService.cacheMerchantMapping(transaction.getMerchantNormalized(), newCategoryId);
        
        log.info("Updated transaction {} category from {} to {}", transactionId, oldCategoryId, newCategoryId);
        
        return convertToResponse(transaction);
    }
    
    private TransactionRequest parseCSVRecord(CSVRecord record) {
        String merchantName = record.get("merchant");
        BigDecimal amount = new BigDecimal(record.get("amount"));
        String currency = record.isMapped("currency") ? record.get("currency") : "INR";
        LocalDate date = parseDate(record.get("date"));
        
        return TransactionRequest.builder()
            .merchantName(merchantName)
            .amount(amount)
            .currency(currency)
            .transactionDate(date)
            .build();
    }
    
    private LocalDate parseDate(String dateStr) {
        for (DateTimeFormatter formatter : DATE_FORMATTERS) {
            try {
                return LocalDate.parse(dateStr, formatter);
            } catch (DateTimeParseException e) {
                // Try next formatter
            }
        }
        throw new RuntimeException("Unable to parse date: " + dateStr);
    }
    
    private String normalizeMerchantName(String merchantName) {
        return merchantName.toLowerCase()
            .replaceAll("[^a-z0-9\\s]", "")
            .trim()
            .replaceAll("\\s+", " ");
    }
    
    private TransactionResponse convertToResponse(Transaction transaction) {
        Category category = null;
        if (transaction.getCategoryId() != null) {
            category = categoryRepository.findById(transaction.getCategoryId()).orElse(null);
        }
        
        TransactionResponse.CategoryResponse categoryResponse = null;
        if (category != null) {
            categoryResponse = TransactionResponse.CategoryResponse.builder()
                .categoryId(category.getCategoryId())
                .categoryName(category.getCategoryName())
                .icon(category.getIcon())
                .color(category.getColor())
                .build();
        }
        
        return TransactionResponse.builder()
            .transactionId(transaction.getTransactionId())
            .merchantName(transaction.getMerchantName())
            .merchantNormalized(transaction.getMerchantNormalized())
            .amount(transaction.getAmount())
            .currency(transaction.getCurrency())
            .transactionDate(transaction.getTransactionDate())
            .category(categoryResponse)
            .confidenceScore(transaction.getConfidenceScore())
            .isUserCorrected(transaction.getIsUserCorrected())
            .createdAt(transaction.getCreatedAt())
            .build();
    }
}
