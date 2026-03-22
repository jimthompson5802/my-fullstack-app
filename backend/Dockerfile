# Use Python 3.14 slim base image
FROM python:3.14-slim

# Set working directory
WORKDIR /app

# Copy pyproject.toml for dependency installation
COPY pyproject.toml ./

# Install dependencies from pyproject.toml
RUN pip install --no-cache-dir .

# Copy application code
COPY src/ ./src/

# Expose port 8000
EXPOSE 8000

# Run uvicorn server
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
