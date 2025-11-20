package com.fincategorizer.category.repository;

import com.fincategorizer.category.entity.Category;
import com.fincategorizer.category.entity.CategoryType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
    
    List<Category> findByUserIdOrUserIdIsNullOrderByCategoryName(Long userId);
    
    List<Category> findByCategoryType(CategoryType categoryType);
    
    Optional<Category> findByCategoryIdAndUserId(Long categoryId, Long userId);
    
    boolean existsByCategoryNameAndUserId(String categoryName, Long userId);
}
