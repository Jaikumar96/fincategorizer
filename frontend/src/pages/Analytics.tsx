import React, { useState, useEffect } from 'react';
import {
  Container,
  Grid,
  Paper,
  Typography,
  Box,
  CircularProgress,
} from '@mui/material';
import {
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { api } from '../services/api';

interface AccuracyData {
  overallAccuracy: number;
  totalTransactions: number;
  correctPredictions: number;
  userCorrections: number;
  avgConfidenceScore?: number;
}

interface CategoryDistribution {
  categoryId: number;
  categoryName: string;
  icon: string;
  color: string;
  amount: number;
  percentage: number;
  transactionCount: number;
}

interface TrendData {
  date: string;
  totalAmount: number;
  transactionCount: number;
  avgConfidence: number;
}

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82CA9D', '#FFC658', '#FF6B9D'];

const Analytics: React.FC = () => {
  const [accuracy, setAccuracy] = useState<AccuracyData | null>(null);
  const [distribution, setDistribution] = useState<CategoryDistribution[]>([]);
  const [trends, setTrends] = useState<TrendData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAnalytics();
  }, []);

  const loadAnalytics = async () => {
    try {
      const [accuracyRes, distributionRes, trendsRes] = await Promise.all([
        api.analytics.accuracy(),
        api.analytics.categoryDistribution(),
        api.analytics.trends(),
      ]);

      setAccuracy(accuracyRes.data);
      setDistribution(distributionRes.data.distribution || []);
      setTrends(trendsRes.data.trends || []);
    } catch (err) {
      console.error('Failed to load analytics', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" gutterBottom>
        Analytics Dashboard
      </Typography>

      {/* Accuracy Stats */}
      {accuracy && (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Paper sx={{ p: 3, textAlign: 'center' }}>
              <Typography variant="h3" color="primary">
                {accuracy.overallAccuracy.toFixed(1)}%
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Overall Accuracy
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Paper sx={{ p: 3, textAlign: 'center' }}>
              <Typography variant="h3">{accuracy.totalTransactions}</Typography>
              <Typography variant="body2" color="textSecondary">
                Total Transactions
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Paper sx={{ p: 3, textAlign: 'center' }}>
              <Typography variant="h3" color="success.main">
                {accuracy.correctPredictions}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                Correct Predictions
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Paper sx={{ p: 3, textAlign: 'center' }}>
              <Typography variant="h3" color="warning.main">
                {accuracy.userCorrections}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                User Corrected
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      )}

      <Grid container spacing={3}>
        {/* Category Distribution Pie Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Category Distribution
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={distribution}
                  dataKey="transactionCount"
                  nameKey="categoryName"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label={(entry) => `${entry.categoryName}: ${entry.transactionCount}`}
                >
                  {distribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Spending Trends Line Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Spending Trends
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={trends}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="totalAmount"
                  stroke="#8884d8"
                  strokeWidth={2}
                  name="Amount"
                />
                <Line
                  type="monotone"
                  dataKey="transactionCount"
                  stroke="#82ca9d"
                  strokeWidth={2}
                  name="Count"
                />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Confidence Trends */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Model Confidence Over Time
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={trends}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis domain={[0, 1]} />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="avgConfidence"
                  stroke="#FF8042"
                  strokeWidth={2}
                  name="Avg Confidence"
                />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>
    </Container>
  );
};

export default Analytics;
