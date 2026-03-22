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

## Technical Requirements

- The frontend must be implemented using TypeScript and React.
- The backend must be implemented using Python and FastAPI.

## Authentication & Authorization

- No authentication or authorization is required between the user and the frontend.
- No authentication or authorization is required between the frontend and the backend API.


## Compute Location & API Recommendation

Recommendation: perform the numeric computation on the backend service (FastAPI). Rationale:

- Ensures consistent numeric precision and rounding (use Python's Decimal on the backend).
- Centralizes error handling (e.g., divide-by-zero) and logging/auditing.
- Avoids JavaScript floating-point pitfalls for critical results.

Frontend responsibilities:

- Validate input locally (numeric, allowed range, max precision) and disable the `Compute` button until inputs are valid.
- Send the validated inputs and selected operation to the backend.
- Show a loading indicator while awaiting response and render errors or the result in the `Answer` field.

API Contract (recommended):

- Endpoint: `POST /api/compute`
- Request JSON:
  {
    "x": string,        // decimal representation (recommended) or number
    "y": string,        // decimal representation (recommended) or number
    "op": "add|subtract|multiply|divide"
  }
- Success Response (200):
  {
    "result": string    // decimal representation as string to preserve precision
  }
- Error Responses:
  - 400 Bad Request: validation errors, payload missing or malformed. Example body: `{ "error": "Invalid input", "code": "INVALID_INPUT" }`
  - 422 Unprocessable Entity: domain errors such as divide-by-zero. Example: `{ "error": "Division by zero", "code": "DIVIDE_BY_ZERO" }`
  - 500 Internal Server Error: unexpected failures. Example: `{ "error": "Internal error", "code": "SERVER_ERROR" }`

Notes / Implementation hints:

- Backend should parse `x` and `y` into `Decimal` and perform the operation, returning a rounded/normalized string according to the precision policy.
- Frontend may send values as strings to avoid JS float rounding before backend conversion.
- The frontend should display friendly error messages and not expose internal error detail; logging of inputs and errors should happen server-side.
- Unit tests are not required for this simple calculator implementation.

## UI → API Mapping

- `X` input: UI accepts numeric characters and optional decimal point. Frontend stores the value as a trimmed string and validates it locally (regex or numeric parse). When calling the API, send `x` as a string containing the decimal representation (e.g. "12.34").
- `Y` input: same rules as `X`; send as `y` (string).
- Operation (`op`): map selected radio to one of `add`, `subtract`, `multiply`, `divide` and send as the `op` string in the payload.
- `Compute` button: enabled only when both `X` and `Y` pass validation; clicking posts JSON `{ "x": "...", "y": "...", "op": "..." }` with `Content-Type: application/json`.
- `Answer` field: display the `result` string returned by the API; format for display (grouping, locale) only after parsing the returned decimal string.
- Errors: frontend should treat non-2xx responses as errors and display friendly messages; do not mutate the input values on error.

## Logging and Validation

- Frontend logging: when the user clicks `Compute`, the frontend MUST write concise log messages for each major step: `compute_clicked`, `validation_failed` (include which field failed), `request_sent` (include `op`, `x`, `y`), `response_received` (include status code and `error.code` if present), and `displayed_result` (include `result`). Logs are for diagnostics only and should not expose internal stack traces.

- Backend validation and logging: the backend MUST validate all incoming request parameters and MUST NOT trust client-side validation. Validation rules:
  - `x` and `y` must be present and be valid decimal representations (parseable by Python's `Decimal`).
  - Reject `NaN`, `Infinity`, or non-numeric strings.
  - (Optional) Enforce reasonable size/precision limits to avoid excessive resource use; return `400` if limits are exceeded.

  On each request the backend MUST write log messages for: `request_received` (include received payload), `validation_failed` (include which field and why), `validation_passed`, `operation_performed` (include `op` and operands), and `result_sent` or `error_sent` (include `error.code`). Logs may include enough context for debugging but must avoid leaking sensitive data.

- Error responses: if validation fails, return `400 Bad Request` with body:

  {
    "error": "Invalid input",
    "code": "INVALID_INPUT",
    "details": { "field": "reason" }
  }

  For domain errors (e.g., divide-by-zero) return `422 Unprocessable Entity` with body:

  {
    "error": "Division by zero",
    "code": "DIVIDE_BY_ZERO"
  }

  For unexpected server errors return `500 Internal Server Error` with a generic message and `code: SERVER_ERROR`.

  The frontend should log the error event (`response_received` with error code) and display a friendly message to the user.
