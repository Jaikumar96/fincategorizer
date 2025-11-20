package com.fincategorizer.category.service;

import com.fincategorizer.category.dto.CategoryRequest;
import com.fincategorizer.category.dto.CategoryResponse;
import com.fincategorizer.category.exception.CategoryAlreadyExistsException;
import com.fincategorizer.category.entity.Category;
import com.fincategorizer.category.entity.CategoryType;
import com.fincategorizer.category.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class CategoryService {
    
    private final CategoryRepository categoryRepository;
    
    @Transactional(readOnly = true)
    public List<CategoryResponse> getAllCategories(Long userId) {
        log.info("Fetching categories for user: {}", userId);
        List<Category> categories = categoryRepository.findByUserIdOrUserIdIsNullOrderByCategoryName(userId);
        return categories.stream()
            .map(this::convertToResponse)
            .collect(Collectors.toList());
    }
    
    @Transactional
    public CategoryResponse createCategory(Long userId, CategoryRequest request) {
        log.info("Creating category for user: {}, name: {}", userId, request.getCategoryName());
        
        if (categoryRepository.existsByCategoryNameAndUserId(request.getCategoryName(), userId)) {
            throw new CategoryAlreadyExistsException("Category already exists: " + request.getCategoryName());
        }
        
        Category category = Category.builder()
            .userId(userId)
            .categoryName(request.getCategoryName())
            .categoryType(CategoryType.CUSTOM)
            .parentCategoryId(request.getParentCategoryId())
            .icon(request.getIcon())
            .color(request.getColor())
            .build();
        
        category = categoryRepository.save(category);
        return convertToResponse(category);
    }
    
    @Transactional
    public CategoryResponse updateCategory(Long categoryId, Long userId, CategoryRequest request) {
        log.info("Updating category: {} for user: {}", categoryId, userId);
        
        Category category = categoryRepository.findByCategoryIdAndUserId(categoryId, userId)
            .orElseThrow(() -> new RuntimeException("Category not found or unauthorized"));
        
        if (category.getCategoryType() == CategoryType.DEFAULT) {
            throw new RuntimeException("Cannot modify default categories");
        }
        
        category.setCategoryName(request.getCategoryName());
        category.setParentCategoryId(request.getParentCategoryId());
        category.setIcon(request.getIcon());
        category.setColor(request.getColor());
        
        category = categoryRepository.save(category);
        return convertToResponse(category);
    }
    
    @Transactional
    public void deleteCategory(Long categoryId, Long userId) {
        log.info("Deleting category: {} for user: {}", categoryId, userId);
        
        Category category = categoryRepository.findByCategoryIdAndUserId(categoryId, userId)
            .orElseThrow(() -> new RuntimeException("Category not found or unauthorized"));
        
        if (category.getCategoryType() == CategoryType.DEFAULT) {
            throw new RuntimeException("Cannot delete default categories");
        }
        
        categoryRepository.delete(category);
    }
    
    private CategoryResponse convertToResponse(Category category) {
        return CategoryResponse.builder()
            .categoryId(category.getCategoryId())
            .categoryName(category.getCategoryName())
            .categoryType(category.getCategoryType().name())
            .parentCategoryId(category.getParentCategoryId())
            .icon(category.getIcon())
            .color(category.getColor())
            .createdAt(category.getCreatedAt())
            .build();
    }
}
