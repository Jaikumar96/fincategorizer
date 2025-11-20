package com.fincategorizer.transaction.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class CacheService {
    
    private final RedisTemplate<String, Object> redisTemplate;
    
    @Value("${cache.merchant-mapping-ttl:604800}")
    private long merchantMappingTtl;
    
    private static final String MERCHANT_CACHE_PREFIX = "merchant:";
    
    public void cacheMerchantMapping(String merchantNormalized, Long categoryId) {
        String key = MERCHANT_CACHE_PREFIX + merchantNormalized;
        try {
            redisTemplate.opsForValue().set(key, categoryId, merchantMappingTtl, TimeUnit.SECONDS);
            log.debug("Cached merchant mapping: {} -> {}", merchantNormalized, categoryId);
        } catch (Exception e) {
            log.error("Error caching merchant mapping", e);
        }
    }
    
    public Optional<Long> getCachedCategory(String merchantNormalized) {
        String key = MERCHANT_CACHE_PREFIX + merchantNormalized;
        try {
            Object value = redisTemplate.opsForValue().get(key);
            if (value != null) {
                log.debug("Cache hit for merchant: {}", merchantNormalized);
                return Optional.of(Long.valueOf(value.toString()));
            }
        } catch (Exception e) {
            log.error("Error retrieving cached category", e);
        }
        return Optional.empty();
    }
    
    public void invalidateCache(String merchantNormalized) {
        String key = MERCHANT_CACHE_PREFIX + merchantNormalized;
        try {
            redisTemplate.delete(key);
            log.debug("Invalidated cache for merchant: {}", merchantNormalized);
        } catch (Exception e) {
            log.error("Error invalidating cache", e);
        }
    }
}
