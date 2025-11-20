package com.fincategorizer.analytics.service;

import com.fincategorizer.analytics.dto.AccuracyResponse;
import com.fincategorizer.analytics.dto.CategoryDistributionResponse;
import com.fincategorizer.analytics.dto.TrendsResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsService {
    
    private final JdbcTemplate jdbcTemplate;
    
    public AccuracyResponse getAccuracy(Long userId) {
        log.info("Calculating accuracy for user: {}", userId);
        
        String sql = "SELECT COUNT(*) as total, " +
                    "SUM(CASE WHEN is_user_corrected = 0 THEN 1 ELSE 0 END) as correct, " +
                    "SUM(CASE WHEN is_user_corrected = 1 THEN 1 ELSE 0 END) as corrected " +
                    "FROM transactions WHERE user_id = ? AND transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
        
        Map<String, Object> result = jdbcTemplate.queryForMap(sql, userId);
        
        Long total = ((Number) result.get("total")).longValue();
        Long correct = ((Number) result.get("correct")).longValue();
        Long corrected = ((Number) result.get("corrected")).longValue();
        
        Double accuracy = total > 0 ? (correct.doubleValue() / total.doubleValue()) * 100 : 0.0;
        
        return AccuracyResponse.builder()
            .overallAccuracy(accuracy)
            .totalTransactions(total.intValue())
            .correctPredictions(correct.intValue())
            .userCorrected(corrected.intValue())
            .period("Last 30 days")
            .build();
    }
    
    public CategoryDistributionResponse getCategoryDistribution(Long userId) {
        log.info("Getting category distribution for user: {}", userId);
        
        String sql = "SELECT c.category_name, COUNT(t.transaction_id) as count, " +
                    "SUM(t.amount) as total_amount " +
                    "FROM transactions t " +
                    "JOIN categories c ON t.category_id = c.category_id " +
                    "WHERE t.user_id = ? " +
                    "GROUP BY c.category_id, c.category_name " +
                    "ORDER BY count DESC";
        
        List<Map<String, Object>> results = jdbcTemplate.queryForList(sql, userId);
        
        Long totalCount = results.stream()
            .mapToLong(r -> ((Number) r.get("count")).longValue())
            .sum();
        
        List<CategoryDistributionResponse.CategoryData> distribution = new ArrayList<>();
        
        for (Map<String, Object> row : results) {
            String categoryName = (String) row.get("category_name");
            Integer count = ((Number) row.get("count")).intValue();
            Double totalAmount = row.get("total_amount") != null ? 
                ((Number) row.get("total_amount")).doubleValue() : 0.0;
            Double percentage = totalCount > 0 ? (count.doubleValue() / totalCount) * 100 : 0.0;
            
            distribution.add(CategoryDistributionResponse.CategoryData.builder()
                .categoryName(categoryName)
                .count(count)
                .percentage(percentage)
                .totalAmount(totalAmount)
                .build());
        }
        
        return CategoryDistributionResponse.builder()
            .distribution(distribution)
            .build();
    }
    
    public TrendsResponse getTrends(Long userId, Integer days) {
        log.info("Getting trends for user: {} for last {} days", userId, days);
        
        String sql = "SELECT DATE(transaction_date) as date, " +
                    "SUM(amount) as total_amount, " +
                    "COUNT(*) as count, " +
                    "AVG(confidence_score) as avg_confidence " +
                    "FROM transactions " +
                    "WHERE user_id = ? AND transaction_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                    "GROUP BY DATE(transaction_date) " +
                    "ORDER BY date";
        
        List<Map<String, Object>> results = jdbcTemplate.queryForList(sql, userId, days);
        
        List<TrendsResponse.TrendData> trends = new ArrayList<>();
        
        for (Map<String, Object> row : results) {
            LocalDate date = ((java.sql.Date) row.get("date")).toLocalDate();
            Double totalAmount = ((Number) row.get("total_amount")).doubleValue();
            Integer count = ((Number) row.get("count")).intValue();
            Double avgConfidence = row.get("avg_confidence") != null ? 
                ((Number) row.get("avg_confidence")).doubleValue() : 0.0;
            
            trends.add(TrendsResponse.TrendData.builder()
                .date(date)
                .totalAmount(totalAmount)
                .transactionCount(count)
                .avgConfidence(avgConfidence)
                .build());
        }
        
        return TrendsResponse.builder()
            .trends(trends)
            .build();
    }
}
