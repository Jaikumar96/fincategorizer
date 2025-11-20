import axios, { AxiosInstance, AxiosError } from 'axios';

// API Configuration
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080';

// Create axios instance
const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 seconds
});

// Request interceptor - Add JWT token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor - Handle errors
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      // Unauthorized - clear token and redirect to login
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    } else if (error.response?.status === 429) {
      // Rate limit exceeded
      console.error('Rate limit exceeded. Please try again later.');
    }
    return Promise.reject(error);
  }
);

// Types
export interface Transaction {
  transactionId?: number;
  userId?: number;
  merchantName: string;
  merchantNormalized?: string;
  amount: number;
  currency: string;
  transactionDate: string;
  category?: Category;
  categoryId?: number;
  confidenceScore?: number;
  isUserCorrected?: boolean;
  metadata?: any;
  createdAt?: string;
  updatedAt?: string;
}

export interface Category {
  categoryId: number;
  categoryName: string;
  categoryType?: 'default' | 'custom';
  icon?: string;
  color?: string;
  description?: string;
  transactionCount?: number;
  totalSpent?: number;
}

export interface AlternativeCategory {
  categoryId: number;
  categoryName: string;
  score: number;
}

export interface CategorizationResponse {
  transactionId: number;
  category: Category;
  confidenceScore: number;
  alternatives: AlternativeCategory[];
}

export interface PaginatedResponse<T> {
  content: T[];
  pageable: {
    pageNumber: number;
    pageSize: number;
  };
  totalElements: number;
  totalPages: number;
  last: boolean;
  first: boolean;
}

export interface AnalyticsAccuracy {
  overallAccuracy: number;
  totalTransactions: number;
  correctPredictions: number;
  userCorrections: number;
  avgConfidenceScore: number;
  accuracyTrend: Array<{
    date: string;
    accuracy: number;
    transactions: number;
  }>;
}

export interface CategoryDistribution {
  totalSpent: number;
  distribution: Array<{
    categoryId: number;
    categoryName: string;
    icon: string;
    color: string;
    amount: number;
    percentage: number;
    transactionCount: number;
  }>;
}

// API Service
export const api = {
  // Authentication
  auth: {
    login: (email: string, password: string) => 
      apiClient.post('/auth/login', { email, password }),
    register: (email: string, password: string, fullName: string) =>
      apiClient.post('/auth/register', { email, password, name: fullName }),
    googleLogin: (code: string) =>
      apiClient.post('/auth/google', { code }),
  },

  // Transactions
  transactions: {
    list: (params?: {
      page?: number;
      size?: number;
      sort?: string;
      startDate?: string;
      endDate?: string;
      categoryId?: number;
      minConfidence?: number;
      maxConfidence?: number;
      search?: string;
    }) =>
      apiClient.get<PaginatedResponse<Transaction>>('/api/transactions', { params }),
    
    get: (id: number) =>
      apiClient.get<Transaction>(`/api/transactions/${id}`),
    
    create: (transaction: Omit<Transaction, 'transactionId'>) =>
      apiClient.post<CategorizationResponse>('/api/transactions', transaction),
    
    uploadBatch: (file: File) => {
      const formData = new FormData();
      formData.append('file', file);
      return apiClient.post('/api/transactions/batch', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    },
    
    updateCategory: (id: number, categoryId: number, notes?: string) =>
      apiClient.put(`/api/transactions/${id}/category`, { categoryId, notes }),
    
    delete: (id: number) =>
      apiClient.delete(`/api/transactions/${id}`),
  },

  // Categories
  categories: {
    list: () =>
      apiClient.get<{ categories: Category[] }>('/api/categories'),
    
    create: (category: {
      categoryName: string;
      icon: string;
      color: string;
      parentCategoryId?: number;
      description?: string;
    }) =>
      apiClient.post<Category>('/api/categories', category),
    
    update: (id: number, updates: Partial<Category>) =>
      apiClient.put<Category>(`/api/categories/${id}`, updates),
    
    delete: (id: number) =>
      apiClient.delete(`/api/categories/${id}`),
    
    getSuggestion: (merchantName: string) =>
      apiClient.get(`/api/categories/merchants/${encodeURIComponent(merchantName)}`),
  },

  // Analytics
  analytics: {
    accuracy: (days: number = 30) =>
      apiClient.get<AnalyticsAccuracy>('/api/analytics/accuracy', { params: { days } }),
    
    categoryDistribution: (startDate?: string, endDate?: string) =>
      apiClient.get<CategoryDistribution>('/api/analytics/category-distribution', {
        params: { startDate, endDate },
      }),
    
    trends: (groupBy: 'day' | 'week' | 'month' = 'week', startDate?: string, endDate?: string) =>
      apiClient.get('/api/analytics/trends', {
        params: { groupBy, startDate, endDate },
      }),
    
    confidenceScores: () =>
      apiClient.get('/api/analytics/confidence-scores'),
    
    topMerchants: (limit: number = 10, startDate?: string, endDate?: string) =>
      apiClient.get('/api/analytics/top-merchants', {
        params: { limit, startDate, endDate },
      }),
  },
};

export default apiClient;
