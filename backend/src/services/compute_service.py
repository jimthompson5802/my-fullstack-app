from decimal import Decimal


def compute(x: str, y: str, op: str) -> str:
    """
    Perform arithmetic operation on two decimal strings.
    
    Args:
        x: First operand as decimal string
        y: Second operand as decimal string
        op: Operation - one of "add", "subtract", "multiply", "divide"
    
    Returns:
        Result as decimal string
    
    Raises:
        ValueError: If division by zero
    """
    # Parse to Decimal
    x_decimal = Decimal(x.strip())
    y_decimal = Decimal(y.strip())
    
    # Perform operation
    if op == "add":
        result = x_decimal + y_decimal
    elif op == "subtract":
        result = x_decimal - y_decimal
    elif op == "multiply":
        result = x_decimal * y_decimal
    elif op == "divide":
        if y_decimal == 0:
            raise ValueError("Division by zero")
        result = x_decimal / y_decimal
    else:
        raise ValueError(f"Unknown operation: {op}")
    
    # Return canonical Decimal string
    return str(result)
