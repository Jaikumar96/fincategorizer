import React, { useState } from 'react';
import {
  Box,
  Container,
  Paper,
  Typography,
  Button,
  LinearProgress,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
} from '@mui/material';
import { CloudUpload as UploadIcon } from '@mui/icons-material';
import { api } from '../services/api';

interface UploadResult {
  totalRecords: number;
  successCount: number;
  failureCount: number;
  errors: Array<{
    rowNumber: number;
    merchantName: string;
    error: string;
  }>;
}

const TransactionUpload: React.FC = () => {
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [result, setResult] = useState<UploadResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = event.target.files?.[0];
    if (selectedFile) {
      if (!selectedFile.name.endsWith('.csv')) {
        setError('Please select a CSV file');
        return;
      }
      setFile(selectedFile);
      setError(null);
      setResult(null);
    }
  };

  const handleUpload = async () => {
    if (!file) return;

    setUploading(true);
    setError(null);

    try {
      const response = await api.transactions.uploadBatch(file);
      setResult(response.data);
      setFile(null);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Upload failed');
    } finally {
      setUploading(false);
    }
  };

  const downloadSample = () => {
    const csvContent = `date,merchant,amount,currency
2025-11-17,Swiggy,450,INR
2025-11-17,Uber,250,INR
2025-11-16,Amazon,1500,INR
2025-11-16,Zepto,380,INR
2025-11-15,BookMyShow,500,INR`;
    
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'sample_transactions.csv';
    a.click();
  };

  return (
    <Container maxWidth="md" sx={{ mt: 4 }}>
      <Paper sx={{ p: 4 }}>
        <Typography variant="h4" gutterBottom>
          Upload Transactions
        </Typography>
        <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
          Upload a CSV file with your transactions. The system will automatically categorize them using AI.
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 3 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ mb: 3 }}>
          <Typography variant="subtitle2" gutterBottom>
            CSV Format Requirements:
          </Typography>
          <Typography variant="body2" component="ul" sx={{ pl: 2 }}>
            <li>Columns: date, merchant, amount, currency (optional)</li>
            <li>Date format: YYYY-MM-DD, DD/MM/YYYY, or MM/DD/YYYY</li>
            <li>Amount: Numeric value without currency symbol</li>
            <li>Maximum: 1000 transactions per upload</li>
          </Typography>
          <Button
            variant="text"
            size="small"
            onClick={downloadSample}
            sx={{ mt: 1 }}
          >
            Download Sample CSV
          </Button>
        </Box>

        <Box sx={{ mb: 3 }}>
          <input
            accept=".csv"
            style={{ display: 'none' }}
            id="csv-file-upload"
            type="file"
            onChange={handleFileSelect}
          />
          <label htmlFor="csv-file-upload">
            <Button
              variant="outlined"
              component="span"
              startIcon={<UploadIcon />}
              fullWidth
            >
              Select CSV File
            </Button>
          </label>
          {file && (
            <Typography variant="body2" sx={{ mt: 1 }}>
              Selected: {file.name} ({(file.size / 1024).toFixed(2)} KB)
            </Typography>
          )}
        </Box>

        <Button
          variant="contained"
          fullWidth
          onClick={handleUpload}
          disabled={!file || uploading}
        >
          {uploading ? 'Uploading...' : 'Upload and Categorize'}
        </Button>

        {uploading && <LinearProgress sx={{ mt: 2 }} />}

        {result && (
          <Box sx={{ mt: 4 }}>
            <Alert severity="success" sx={{ mb: 2 }}>
              Upload completed! Processed {result.totalRecords} transactions.
            </Alert>

            <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
              <Chip
                label={`Success: ${result.successCount}`}
                color="success"
                variant="outlined"
              />
              <Chip
                label={`Failed: ${result.failureCount}`}
                color="error"
                variant="outlined"
              />
            </Box>

            {result.errors && result.errors.length > 0 && (
              <>
                <Typography variant="subtitle1" gutterBottom>
                  Errors:
                </Typography>
                <TableContainer>
                  <Table size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>Row</TableCell>
                        <TableCell>Merchant</TableCell>
                        <TableCell>Error</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {result.errors.map((err, idx) => (
                        <TableRow key={idx}>
                          <TableCell>{err.rowNumber}</TableCell>
                          <TableCell>{err.merchantName}</TableCell>
                          <TableCell>{err.error}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              </>
            )}
          </Box>
        )}
      </Paper>
    </Container>
  );
};

export default TransactionUpload;
