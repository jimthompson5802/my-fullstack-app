# Backend Documentation

## Overview

This is the backend component of the my-fullstack-app project. It is built using Python and serves as the server-side application that handles API requests, manages data models, and contains business logic.

## Project Structure

```
backend/
├── src/
│   ├── __init__.py          # Marks the directory as a Python package
│   ├── main.py              # FastAPI application and API endpoints
│   ├── api/
│   │   └── __init__.py      # Package marker
│   ├── models/
│   │   ├── __init__.py      # Package marker
│   │   └── payload.py       # Pydantic models for request/response validation
│   └── services/
│       ├── __init__.py      # Package marker
│       └── compute_service.py  # Business logic for compute operations
├── pyproject.toml            # Project metadata and dependencies
├── requirements.txt          # Lists the dependencies required for the backend
└── README.md                 # Documentation for the backend
```

## Getting Started

To set up the backend application, follow these steps:

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd my-fullstack-app/backend
   ```

2. **Install dependencies using uv**:
   ```bash
   uv pip install -e .
   ```

3. **Run the FastAPI application**:
   ```bash
   uv run uvicorn src.main:app --reload --port 8000
   ```

The API will be available at `http://localhost:8000`

Interactive API documentation: `http://localhost:8000/docs`

## API Endpoints

### POST /api/compute

Performs arithmetic operations on two decimal numbers.

**Request Body:**
```json
{
  "x": "10",
  "y": "5",
  "op": "add"
}
```

**Operations:** `add`, `subtract`, `multiply`, `divide`

**Success Response (200):**
```json
{
  "result": "15"
}
```

**Error Response (422 - Division by Zero):**
```json
{
  "error": "Division by zero",
  "code": "DIVIDE_BY_ZERO"
}
```

See the full API specification in `docs/system-spec.md`

## Contributing

If you would like to contribute to the backend, please fork the repository and submit a pull request with your changes. Make sure to follow the coding standards and include tests for any new features.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.