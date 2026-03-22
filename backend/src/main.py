import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import ValidationError
from .models.payload import ComputeRequest, ComputeResponse, ErrorResponse
from .services.compute_service import compute

app = FastAPI()

# Configure CORS origins from environment variable
cors_origins_env = os.getenv("CORS_ORIGINS", "*")
if cors_origins_env == "*":
    cors_origins = ["*"]
else:
    # Parse comma-separated list of origins
    cors_origins = [origin.strip() for origin in cors_origins_env.split(",")]

# Enable CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root():
    return {"message": "Welcome to the calculator backend API!"}


@app.post("/api/compute", response_model=ComputeResponse)
async def compute_endpoint(request: ComputeRequest):
    """
    Perform arithmetic operation on two decimal numbers.
    
    Returns:
        ComputeResponse with result string
        
    Raises:
        HTTPException 400: Invalid input (bad JSON or validation failure)
        HTTPException 422: Domain error (e.g., divide by zero)
        HTTPException 500: Server error
    """
    try:
        # Perform computation
        result = compute(request.x, request.y, request.op)
        return ComputeResponse(result=result)
    
    except ValueError as e:
        # Domain error (e.g., divide by zero)
        error_msg = str(e)
        if "division by zero" in error_msg.lower():
            return JSONResponse(
                status_code=422,
                content={
                    "error": "Division by zero",
                    "code": "DIVIDE_BY_ZERO"
                }
            )
        else:
            # Other domain errors
            return JSONResponse(
                status_code=422,
                content={
                    "error": error_msg,
                    "code": "DOMAIN_ERROR"
                }
            )
    
    except Exception as e:
        # Unexpected server error
        return JSONResponse(
            status_code=500,
            content={
                "error": "Internal error",
                "code": "SERVER_ERROR"
            }
        )


@app.exception_handler(ValidationError)
async def validation_exception_handler(request, exc: ValidationError):
    """Handle Pydantic validation errors."""
    details = {}
    for error in exc.errors():
        field = error["loc"][-1] if error["loc"] else "unknown"
        msg = error["msg"]
        details[field] = msg
    
    return JSONResponse(
        status_code=400,
        content={
            "error": "Invalid input",
            "code": "INVALID_INPUT",
            "details": details
        }
    )


# Additional API routes can be defined here.
