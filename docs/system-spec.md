## Calculator UI Layout (ASCII Diagram)

```
+------------------------------------------------------+ 
|   X: [       ]                                       |
|                                                      |
|   Y: [       ]                                       |
|                                                      |
| ( )add  ( )subtract  ( )multiply  ( )divide          |
|                                                      |
|                [ Compute ]                           |
+------------------------------------------------------+
|------------------------------------------------------|
| Answer: [       ]                                    |
+------------------------------------------------------+
```

## Functional Requirements

1. The user enters numeric values into the X and Y fields.
2. The user selects one of the four operations: add, subtract, multiply, or divide, using the radio buttons.
3. The user clicks the "Compute" button.
4. The system performs the selected operation using the values from X and Y.
5. The result of the computation is displayed in the "Answer" field.
---

## Technical Requirements

- The frontend must be implemented using TypeScript and React.
- The backend must be implemented using Python and FastAPI.

## Authentication & Authorization

- No authentication or authorization is required between the user and the frontend.
- No authentication or authorization is required between the frontend and the backend API.


## 1. Overview

This document describes a simple calculator web application with a React/TypeScript frontend and a FastAPI/Python backend. The backend performs all arithmetic using Python's Decimal for precision and consistency.

## 2. Functional Requirements

1. User enters numeric values into X and Y fields.
2. User selects one of four operations: add, subtract, multiply, or divide.
3. User clicks the "Compute" button.
4. System performs the selected operation using X and Y.
5. Result is displayed in the "Answer" field.

## 3. Technical Requirements

- Frontend: TypeScript + React
- Backend: Python + FastAPI
- No authentication/authorization required between user/frontend/backend.

## 4. UI and User Flow

### Layout

See ASCII diagram above.

### UI → API Mapping

- X and Y: Accept numeric input (including decimals, exponent notation allowed). Store as trimmed strings.
- Operation: Radio buttons map to `add`, `subtract`, `multiply`, `divide`.
- Compute button: Enabled only when both X and Y are non-empty and appear numeric. On click, POSTs JSON to backend.
- Answer field: Displays result from backend. For display, may format using locale, but must preserve backend value.
- Errors: Non-2xx responses are shown as friendly messages. Inputs are not mutated on error.

### Frontend Validation & Logging

- Validate X and Y are non-empty and parseable as numbers (Decimal-compatible). Trim whitespace.
- Do not convert to JS Number before sending; send as string.
- Log major steps: `compute_clicked`, `validation_failed` (with field), `request_sent` (with op, x, y), `response_received` (with status and error.code), `displayed_result` (with result).

## 5. API Contract

### Endpoint

POST /api/compute

### Request JSON Schema
```json
{
  "type": "object",
  "properties": {
    "x": {
      "type": "string",
      "description": "Decimal representation parseable by Python Decimal (may include exponent notation, e.g. '1.23', '1e-3'). Leading/trailing whitespace should be trimmed by the client."
    },
    "y": {
      "type": "string",
      "description": "Decimal representation parseable by Python Decimal."
    },
    "op": {
      "type": "string",
      "enum": ["add", "subtract", "multiply", "divide"]
    }
  },
  "required": ["x", "y", "op"],
  "additionalProperties": false
}
```

### Validation Rules (Backend)

- x and y must be present and parseable by Python's Decimal.
- Reject NaN, Infinity, or non-numeric strings.
- Exponent notation (e.g., '1e-6') is allowed.
- No additional digit/scale/precision limits enforced by spec (implementations may add operational protections).

### Response Schemas

#### Success (200)
```json
{
  "type": "object",
  "properties": {
    "result": { "type": "string", "description": "Decimal string returned by the backend (canonical Decimal string produced by Python Decimal; client should treat this as authoritative)." }
  },
  "required": ["result"],
  "additionalProperties": false
}
```

#### Validation Error (400)
HTTP 400 Bad Request
```json
{
  "error": "Invalid input",
  "code": "INVALID_INPUT",
  "details": { "<field>": "<short reason>" }
}
```

#### Domain Error (422)
HTTP 422 Unprocessable Entity
```json
{
  "error": "Division by zero",
  "code": "DIVIDE_BY_ZERO"
}
```

#### Server Error (500)
HTTP 500 Internal Server Error
```json
{
  "error": "Internal error",
  "code": "SERVER_ERROR"
}
```

### Status Code Mapping

- 400: Malformed JSON or schema validation failure (missing fields, not Decimal-parseable).
- 422: Domain errors after valid parse (e.g., divide-by-zero).
- 500: Unexpected server errors.

### Example Requests & Responses
```
Request:
POST /api/compute
Content-Type: application/json
{
  "x": "12.5",
  "y": "3.25",
  "op": "add"
}
```
```
Success (200):
{
  "result": "15.75"
}
```
```
Divide-by-zero (422):
{
  "error": "Division by zero",
  "code": "DIVIDE_BY_ZERO"
}
```
## 6. Backend Implementation Notes

- Parse x and y using Decimal(x) and Decimal(y) after trimming.
- Reject NaN/Infinity and non-parseable strings with HTTP 400 and a details entry for the offending field.
- For division, if y is zero, return 422 with code: DIVIDE_BY_ZERO.
- Return result as the string form of the Decimal result (no extra rounding mandated by this spec; backend may use Python's str(Decimal)).

## 7. Additional Notes

- This spec intentionally keeps validation minimal (numeric only). If operational limits (max digits, request-size, rate limits, or rounding behavior) are needed, add a separate "Operational Constraints" section.
- Unit tests are not required for this simple calculator implementation.
    "op": {
      "type": "string",
      "enum": ["add", "subtract", "multiply", "divide"]
    }
  },
  "required": ["x", "y", "op"],
  "additionalProperties": false
}

Validation rules (minimal numeric-only)
- The server validates that `x` and `y` are present and parseable by Python's `Decimal()` (client may validate similarly).
- Reject `NaN`, `Infinity`, or non-parseable strings.
- Exponent notation (e.g., "1e-6") is allowed.
- No additional digit/scale/precision limits are enforced by the spec (implementation may enforce operational protections separately).

Response Schemas

Success (200)
```json
{
  "type": "object",
  "properties": {
    "result": { "type": "string", "description": "Decimal string returned by the backend (canonical Decimal string produced by Python Decimal; client should treat this as authoritative)." }
  },
  "required": ["result"],
  "additionalProperties": false
}
```

Validation Error (400)
HTTP 400 Bad Request
Body:
```json
{
  "error": "Invalid input",
  "code": "INVALID_INPUT",
  "details": { "<field>": "<short reason>" }
}
```

- Use 400 for syntactic JSON errors or when `x`/`y` cannot be parsed by `Decimal` or required fields are missing.

Domain Error (422)
HTTP 422 Unprocessable Entity
Body (example for divide-by-zero):
```json
{
  "error": "Division by zero",
  "code": "DIVIDE_BY_ZERO"
}
```

Server Error (500)
HTTP 500 Internal Server Error
Body:
```json
{
  "error": "Internal error",
  "code": "SERVER_ERROR"
}
```

Status-code mapping summary
- 400: malformed JSON or schema validation failure (missing fields, not Decimal-parseable).
- 422: domain errors after valid parse (e.g., divide-by-zero).
- 500: unexpected server errors.

Examples

Request
POST /api/compute
Content-Type: application/json
```json
{
  "x": "12.5",
  "y": "3.25",
  "op": "add"
}
```

Success response (200)
```json
{
  "result": "15.75"
}
```

Divide-by-zero (422)
```json
{
  "error": "Division by zero",
  "code": "DIVIDE_BY_ZERO"
}
```

Frontend notes (minimal)
- Local validation: ensure both `X` and `Y` are non-empty and appear numeric (client may use a simple numeric test or a decimal library). Trim whitespace before validation.
- Do not convert inputs to JS Number if you need to preserve exact string transmitted to the backend; send `x` and `y` as strings exactly as validated.
- Disable the `Compute` button until both fields pass the numeric validation.
- Show a loading indicator while awaiting the response.
- On success, display the `result` string exactly as returned by the backend. For UI-only formatting (grouping/locale), format from the backend string for visual purposes only; keep the canonical value intact.
- Treat any non-2xx response as an error: read `code` (if present) and show a friendly message to the user.

Backend notes (minimal)
- Parse `x` and `y` using `Decimal(x)` and `Decimal(y)` after trimming.
- Reject `NaN`/`Infinity` and non-parseable strings with HTTP 400 and a `details` entry for the offending field.
- For division, if `y` is zero, return 422 with `code: DIVIDE_BY_ZERO`.
- Return `result` as the string form of the Decimal result (no extra rounding mandated by this spec; backend may choose canonical Decimal string formatting such as Python's `str(Decimal)`).

Small clarification for implementers
- This spec intentionally keeps validation minimal (numeric only). If you later need operational limits (max digits, request-size, rate limits, or rounding behavior), add a separate "Operational Constraints" or "Precision Policy" section.

