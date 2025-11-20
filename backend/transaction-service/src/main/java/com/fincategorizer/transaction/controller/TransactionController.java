package com.fincategorizer.transaction.controller;

import com.fincategorizer.transaction.dto.BatchUploadResponse;
import com.fincategorizer.transaction.dto.TransactionRequest;
import com.fincategorizer.transaction.dto.TransactionResponse;
import com.fincategorizer.transaction.dto.UpdateCategoryRequest;
import com.fincategorizer.transaction.service.TransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
@Slf4j
public class TransactionController {
    
    private final TransactionService transactionService;
    
    @PostMapping
    public ResponseEntity<TransactionResponse> createTransaction(
            @RequestHeader("X-User-Id") Long userId,
            @Valid @RequestBody TransactionRequest request) {
        log.info("POST /api/transactions - userId: {}", userId);
        TransactionResponse response = transactionService.createTransaction(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @PostMapping("/batch")
    public ResponseEntity<BatchUploadResponse> uploadBatch(
            @RequestHeader("X-User-Id") Long userId,
            @RequestParam("file") MultipartFile file) {
        log.info("POST /api/transactions/batch - userId: {}, file: {}", userId, file.getOriginalFilename());
        
        if (file.isEmpty()) {
            throw new RuntimeException("File is empty");
        }
        
        if (!file.getOriginalFilename().endsWith(".csv")) {
            throw new RuntimeException("Only CSV files are supported");
        }
        
        BatchUploadResponse response = transactionService.uploadBatch(userId, file);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping
    public ResponseEntity<Page<TransactionResponse>> getTransactions(
            @RequestHeader("X-User-Id") Long userId,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "transactionDate") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection) {
        
        log.info("GET /api/transactions - userId: {}, page: {}, size: {}", userId, page, size);
        
        Sort sort = Sort.by(Sort.Direction.fromString(sortDirection), sortBy);
        PageRequest pageRequest = PageRequest.of(page, size, sort);
        
        Page<TransactionResponse> response = transactionService.getTransactions(
            userId, categoryId, startDate, endDate, pageRequest);
        
        return ResponseEntity.ok(response);
    }
    
    @PutMapping("/{id}/category")
    public ResponseEntity<TransactionResponse> updateCategory(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long id,
            @RequestBody UpdateCategoryRequest request) {
        log.info("PUT /api/transactions/{}/category - userId: {}, newCategoryId: {}", id, userId, request.getCategoryId());
        TransactionResponse response = transactionService.updateCategory(id, userId, request.getCategoryId(), request.getNotes());
        return ResponseEntity.ok(response);
    }
}
