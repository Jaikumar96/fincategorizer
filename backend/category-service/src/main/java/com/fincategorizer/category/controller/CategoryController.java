package com.fincategorizer.category.controller;

import com.fincategorizer.category.dto.CategoryRequest;
import com.fincategorizer.category.dto.CategoryResponse;
import com.fincategorizer.category.service.CategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@Slf4j
public class CategoryController {
    
    private final CategoryService categoryService;
    
    @GetMapping
    public ResponseEntity<List<CategoryResponse>> getAllCategories(
            @RequestHeader("X-User-Id") Long userId) {
        log.info("GET /api/categories - userId: {}", userId);
        List<CategoryResponse> categories = categoryService.getAllCategories(userId);
        return ResponseEntity.ok(categories);
    }
    
    @PostMapping
    public ResponseEntity<CategoryResponse> createCategory(
            @RequestHeader("X-User-Id") Long userId,
            @Valid @RequestBody CategoryRequest request) {
        log.info("POST /api/categories - userId: {}", userId);
        CategoryResponse response = categoryService.createCategory(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<CategoryResponse> updateCategory(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long id,
            @Valid @RequestBody CategoryRequest request) {
        log.info("PUT /api/categories/{} - userId: {}", id, userId);
        CategoryResponse response = categoryService.updateCategory(id, userId, request);
        return ResponseEntity.ok(response);
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCategory(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long id) {
        log.info("DELETE /api/categories/{} - userId: {}", id, userId);
        categoryService.deleteCategory(id, userId);
        return ResponseEntity.noContent().build();
    }
}
