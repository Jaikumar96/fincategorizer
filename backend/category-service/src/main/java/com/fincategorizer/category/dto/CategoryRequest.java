package com.fincategorizer.category.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CategoryRequest {
    
    @NotBlank(message = "Category name is required")
    @Size(max = 100, message = "Category name must not exceed 100 characters")
    private String categoryName;
    
    private Long parentCategoryId;
    
    @Size(max = 10, message = "Icon must not exceed 10 characters")
    private String icon;
    
    @Size(min = 7, max = 7, message = "Color must be in hex format (#RRGGBB)")
    private String color;
}
