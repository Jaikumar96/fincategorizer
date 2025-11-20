package com.fincategorizer.transaction.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "categories")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Category {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "category_id")
    private Long categoryId;
    
    @Column(name = "user_id")
    private Long userId;
    
    @Column(name = "category_name", nullable = false, length = 100)
    private String categoryName;
    
    @Column(name = "category_type", nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private CategoryType categoryType;
    
    @Column(name = "parent_category_id")
    private Long parentCategoryId;
    
    @Column(length = 10)
    private String icon;
    
    @Column(length = 7)
    private String color;
}
