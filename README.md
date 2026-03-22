# Calculator Full-Stack Application

A simple calculator web application with a React/TypeScript frontend and FastAPI/Python backend that performs precise decimal arithmetic.

## Features

- Perform basic arithmetic operations: add, subtract, multiply, divide
- Precise decimal arithmetic using Python's Decimal class
- Clean UI with input validation
- Comprehensive error handling

## Prerequisites

- Python 3.14+ with uv package manager
- Node.js and npm

## Backend Setup

1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```

2. Install dependencies using uv:
   ```bash
   uv pip install -e .
   ```

3. Run the development server:
   ```bash
   uv run uvicorn src.main:app --reload --port 8000
   ```

The backend API will be available at `http://localhost:8000`

API Documentation: `http://localhost:8000/docs`

## Frontend Setup

1. Navigate to the `frontend` directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm start
   ```

The frontend will be available at `http://localhost:3000`

## Project Structure

```
my-fullstack-app/
├── backend/
│   ├── src/
│   │   ├── main.py          # FastAPI application and /api/compute endpoint
│   │   ├── models/          # Pydantic models for request/response
│   │   └── services/        # Business logic (compute function)
│   ├── pyproject.toml       # Python dependencies
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── App.tsx      # Main app component
│   │   │   └── Calculator.tsx  # Calculator UI component
│   │   ├── types/
│   │   │   └── api.ts       # TypeScript type definitions
│   │   └── index.ts         # Entry point
│   ├── public/
│   │   └── index.html       # HTML template
│   ├── package.json         # Node dependencies
│   ├── tsconfig.json        # TypeScript configuration
│   └── webpack.config.js    # Webpack configuration
└── docs/
    └── system-spec.md       # Full system specification
```

## API Endpoint

### POST /api/compute

Request:
```json
{
  "x": "12.5",
  "y": "3.25",
  "op": "add"
}
```

Response (success):
```json
{
  "result": "15.75"
}
```

Response (error):
```json
{
  "error": "Division by zero",
  "code": "DIVIDE_BY_ZERO"
}
```

Supported operations: `add`, `subtract`, `multiply`, `divide`

## Testing the Application

1. Start the backend server (see Backend Setup above)
2. Start the frontend server (see Frontend Setup above)
3. Navigate to `http://localhost:3000`
4. Enter values in the X and Y fields
5. Select an operation
6. Click "Compute"
7. View the result in the Answer field

## Error Handling

The application handles:

- Invalid input (non-numeric values)
- Division by zero
- Network errors
- Server errors

All errors are displayed as user-friendly messages in the Answer field.

## Implementation Details

See [docs/system-spec.md](docs/system-spec.md) for the complete system specification including:
- Detailed API contract
- Request/response schemas
- Error codes and status mappings
- Frontend validation requirements
- Backend implementation notes