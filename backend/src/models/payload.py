from pydantic import BaseModel, field_validator
from typing import Literal


class ComputeRequest(BaseModel):
    x: str
    y: str
    op: Literal["add", "subtract", "multiply", "divide"]

    class Config:
        extra = "forbid"  # Reject additional properties

    @field_validator("x", "y")
    @classmethod
    def validate_decimal_string(cls, v: str) -> str:
        """Validate that the string can be parsed as a Decimal."""
        from decimal import Decimal, InvalidOperation
        
        if not v or not isinstance(v, str):
            raise ValueError("must be a non-empty string")
        
        # Trim whitespace
        v = v.strip()
        
        try:
            d = Decimal(v)
            # Reject NaN and Infinity
            if not d.is_finite():
                raise ValueError("must be a finite number (not NaN or Infinity)")
        except InvalidOperation:
            raise ValueError("must be a valid decimal number")
        
        return v


class ComputeResponse(BaseModel):
    result: str


class ErrorResponse(BaseModel):
    error: str
    code: str
    details: dict[str, str] | None = None
