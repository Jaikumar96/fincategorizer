import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Grid,
  Card,
  CardContent,
  Typography,
  Chip,
  Button,
  CircularProgress,
  Alert,
  Paper,
} from '@mui/material';
import {
  AccountBalance,
  TrendingUp,
  CheckCircle,
  Warning,
} from '@mui/icons-material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import { api, Transaction, Category } from '../services/api';

const Dashboard: React.FC = () => {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [stats, setStats] = useState({
    total: 0,
    highConfidence: 0,
    needsReview: 0,
    avgConfidence: 0,
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      
      // Load transactions
      const txnResponse = await api.transactions.list({ page: 0, size: 100 });
      const txns = txnResponse.data.content;
      setTransactions(txns);
      
      // Load categories
      const catResponse = await api.categories.list();
      setCategories(catResponse.data.categories);
      
      // Calculate stats
      const total = txns.length;
      const highConf = txns.filter(t => (t.confidenceScore || 0) >= 0.85).length;
      const needsReview = txns.filter(t => (t.confidenceScore || 0) < 0.85 && (t.confidenceScore || 0) >= 0.60).length;
      const avgConf = txns.reduce((sum, t) => sum + (t.confidenceScore || 0), 0) / (total || 1);
      
      setStats({
        total,
        highConfidence: highConf,
        needsReview,
        avgConfidence: avgConf,
      });
      
      setError(null);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load data');
      console.error('Error loading data:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyTransaction = async (id: number, newCategoryId: number) => {
    try {
      await api.transactions.updateCategory(id, newCategoryId, 'User verified');
      loadData(); // Reload data
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update transaction');
    }
  };

  const getConfidenceColor = (confidence: number): "success" | "warning" | "error" => {
    if (confidence >= 0.85) return 'success';
    if (confidence >= 0.60) return 'warning';
    return 'error';
  };

  const columns: GridColDef[] = [
    { field: 'transactionDate', headerName: 'Date', width: 120,
      valueFormatter: (params) => new Date(params.value).toLocaleDateString()
    },
    { field: 'merchantName', headerName: 'Merchant', width: 200 },
    { field: 'amount', headerName: 'Amount', width: 120,
      valueFormatter: (params) => `₹${params.value?.toFixed(2)}`
    },
    {
      field: 'category',
      headerName: 'Category',
      width: 180,
      renderCell: (params) => (
        <Chip
          label={params.value?.categoryName || 'Unknown'}
          icon={<span>{params.value?.icon || '📦'}</span>}
          size="small"
          sx={{ backgroundColor: params.value?.color || '#ccc' }}
        />
      ),
    },
    {
      field: 'confidenceScore',
      headerName: 'Confidence',
      width: 130,
      renderCell: (params) => (
        <Chip
          label={`${(params.value * 100).toFixed(1)}%`}
          color={getConfidenceColor(params.value)}
          size="small"
        />
      ),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 150,
      renderCell: (params) => {
        const conf = params.row.confidenceScore || 0;
        if (conf < 0.85 && conf >= 0.60) {
          return (
            <Button
              variant="outlined"
              size="small"
              color="warning"
              onClick={() => handleVerifyTransaction(params.row.transactionId, params.row.category.categoryId)}
            >
              Verify
            </Button>
          );
        }
        return null;
      },
    },
  ];

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Stats Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="body2">
                    Total Transactions
                  </Typography>
                  <Typography variant="h4">{stats.total}</Typography>
                </Box>
                <AccountBalance sx={{ fontSize: 40, color: '#1976d2' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="body2">
                    High Confidence
                  </Typography>
                  <Typography variant="h4">{stats.highConfidence}</Typography>
                  <Typography variant="caption" color="success.main">
                    ≥85% accuracy
                  </Typography>
                </Box>
                <CheckCircle sx={{ fontSize: 40, color: '#4caf50' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="body2">
                    Needs Review
                  </Typography>
                  <Typography variant="h4">{stats.needsReview}</Typography>
                  <Typography variant="caption" color="warning.main">
                    60-85% confidence
                  </Typography>
                </Box>
                <Warning sx={{ fontSize: 40, color: '#ff9800' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="textSecondary" gutterBottom variant="body2">
                    Avg Confidence
                  </Typography>
                  <Typography variant="h4">
                    {(stats.avgConfidence * 100).toFixed(1)}%
                  </Typography>
                  <Typography variant="caption" color="textSecondary">
                    Model accuracy
                  </Typography>
                </Box>
                <TrendingUp sx={{ fontSize: 40, color: '#2196f3' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Transactions Table */}
      <Paper sx={{ p: 2 }}>
        <Typography variant="h6" gutterBottom>
          Recent Transactions
        </Typography>
        <Box sx={{ height: 500, width: '100%' }}>
          <DataGrid
            rows={transactions}
            columns={columns}
            getRowId={(row) => row.transactionId || 0}
            initialState={{
              pagination: {
                paginationModel: { pageSize: 10 },
              },
            }}
            pageSizeOptions={[10, 25, 50]}
            checkboxSelection={false}
            disableRowSelectionOnClick
          />
        </Box>
      </Paper>
    </Container>
  );
};

export default Dashboard;
