import React, { useState } from 'react';
import { Operation, ComputeRequest, ComputeResponse, ErrorResponse } from '../types/api';

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:8000';

const Calculator: React.FC = () => {
  const [x, setX] = useState('');
  const [y, setY] = useState('');
  const [operation, setOperation] = useState<Operation>('add');
  const [result, setResult] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  // Validate that a string is a valid decimal number
  const isValidDecimal = (value: string): boolean => {
    if (!value || value.trim() === '') {
      return false;
    }
    
    const trimmed = value.trim();
    
    // Try to parse as a number
    // Allow formats like: 123, 12.34, 1e-6, -5.67
    try {
      const num = parseFloat(trimmed);
      if (isNaN(num) || !isFinite(num)) {
        return false;
      }
      // Additional check: ensure it looks like a number
      return /^-?\d+(\.\d+)?(e[+-]?\d+)?$/i.test(trimmed);
    } catch {
      return false;
    }
  };

  // Check if compute button should be enabled
  const isFormValid = (): boolean => {
    return isValidDecimal(x) && isValidDecimal(y);
  };

  // Log function for tracking
  const log = (event: string, data?: any) => {
    console.log(`[Calculator] ${event}`, data || '');
  };

  // Handle compute button click
  const handleCompute = async () => {
    log('compute_clicked');
    
    // Clear previous results/errors
    setError('');
    setResult('');
    
    // Validate inputs
    if (!isValidDecimal(x)) {
      log('validation_failed', { field: 'x' });
      setError('X must be a valid number');
      return;
    }
    
    if (!isValidDecimal(y)) {
      log('validation_failed', { field: 'y' });
      setError('Y must be a valid number');
      return;
    }
    
    // Prepare request
    const request: ComputeRequest = {
      x: x.trim(),
      y: y.trim(),
      op: operation,
    };
    
    log('request_sent', { op: request.op, x: request.x, y: request.y });
    
    setLoading(true);
    
    try {
      const response = await fetch(`${API_BASE_URL}/api/compute`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(request),
      });
      
      log('response_received', { status: response.status });
      
      if (response.ok) {
        const data: ComputeResponse = await response.json();
        setResult(data.result);
        log('displayed_result', { result: data.result });
      } else {
        // Handle error response
        const errorData: ErrorResponse = await response.json();
        log('response_received', { status: response.status, code: errorData.code });
        
        // Map error codes to friendly messages
        let friendlyMessage = errorData.error;
        switch (errorData.code) {
          case 'DIVIDE_BY_ZERO':
            friendlyMessage = 'Cannot divide by zero';
            break;
          case 'INVALID_INPUT':
            friendlyMessage = 'Invalid input: ' + (errorData.details ? Object.values(errorData.details).join(', ') : errorData.error);
            break;
          case 'SERVER_ERROR':
            friendlyMessage = 'Server error. Please try again later.';
            break;
          default:
            friendlyMessage = errorData.error || 'An error occurred';
        }
        
        setError(friendlyMessage);
      }
    } catch (err) {
      log('response_received', { status: 'network_error' });
      setError('Network error. Please check your connection.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      <h1 style={styles.title}>Calculator</h1>
      
      <div style={styles.form}>
        <div style={styles.inputGroup}>
          <label style={styles.label}>X:</label>
          <input
            type="text"
            value={x}
            onChange={(e) => setX(e.target.value)}
            style={styles.input}
            placeholder="Enter a number"
          />
        </div>
        
        <div style={styles.inputGroup}>
          <label style={styles.label}>Y:</label>
          <input
            type="text"
            value={y}
            onChange={(e) => setY(e.target.value)}
            style={styles.input}
            placeholder="Enter a number"
          />
        </div>
        
        <div style={styles.radioGroup}>
          <label style={styles.radioLabel}>
            <input
              type="radio"
              name="operation"
              value="add"
              checked={operation === 'add'}
              onChange={(e) => setOperation(e.target.value as Operation)}
            />
            add
          </label>
          
          <label style={styles.radioLabel}>
            <input
              type="radio"
              name="operation"
              value="subtract"
              checked={operation === 'subtract'}
              onChange={(e) => setOperation(e.target.value as Operation)}
            />
            subtract
          </label>
          
          <label style={styles.radioLabel}>
            <input
              type="radio"
              name="operation"
              value="multiply"
              checked={operation === 'multiply'}
              onChange={(e) => setOperation(e.target.value as Operation)}
            />
            multiply
          </label>
          
          <label style={styles.radioLabel}>
            <input
              type="radio"
              name="operation"
              value="divide"
              checked={operation === 'divide'}
              onChange={(e) => setOperation(e.target.value as Operation)}
            />
            divide
          </label>
        </div>
        
        <button
          onClick={handleCompute}
          disabled={!isFormValid() || loading}
          style={{
            ...styles.button,
            ...((!isFormValid() || loading) ? styles.buttonDisabled : {}),
          }}
        >
          {loading ? 'Computing...' : 'Compute'}
        </button>
      </div>
      
      <div style={styles.resultSection}>
        <div style={styles.inputGroup}>
          <label style={styles.label}>Answer:</label>
          <input
            type="text"
            value={error || result}
            readOnly
            style={{
              ...styles.input,
              ...(error ? styles.errorInput : {}),
            }}
            placeholder="Result will appear here"
          />
        </div>
      </div>
    </div>
  );
};

// Inline styles for simplicity
const styles: Record<string, React.CSSProperties> = {
  container: {
    maxWidth: '600px',
    margin: '50px auto',
    padding: '30px',
    border: '2px solid #333',
    borderRadius: '8px',
    fontFamily: 'Arial, sans-serif',
  },
  title: {
    textAlign: 'center',
    marginBottom: '30px',
  },
  form: {
    marginBottom: '30px',
  },
  inputGroup: {
    marginBottom: '20px',
    display: 'flex',
    alignItems: 'center',
  },
  label: {
    minWidth: '80px',
    fontWeight: 'bold',
  },
  input: {
    flex: 1,
    padding: '8px',
    fontSize: '16px',
    border: '1px solid #ccc',
    borderRadius: '4px',
  },
  errorInput: {
    color: 'red',
    borderColor: 'red',
  },
  radioGroup: {
    marginBottom: '20px',
    display: 'flex',
    gap: '20px',
  },
  radioLabel: {
    display: 'flex',
    alignItems: 'center',
    gap: '5px',
    cursor: 'pointer',
  },
  button: {
    width: '100%',
    padding: '12px',
    fontSize: '18px',
    fontWeight: 'bold',
    color: 'white',
    backgroundColor: '#007bff',
    border: 'none',
    borderRadius: '4px',
    cursor: 'pointer',
  },
  buttonDisabled: {
    backgroundColor: '#ccc',
    cursor: 'not-allowed',
  },
  resultSection: {
    borderTop: '2px solid #333',
    paddingTop: '20px',
  },
};

export default Calculator;
