# Use a minimal base image
FROM python:3.11-alpine

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies
RUN apk add --no-cache \
    libffi-dev \
    gcc \
    musl-dev \
    linux-headers

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Create working directory
WORKDIR /app

# Copy only necessary files
COPY --chown=appuser:appgroup . .

# Install Python dependencies
RUN pip install --no-cache-dir Flask

# Switch to non-root user
USER appuser

# Expose the port
EXPOSE 8080

# Run the Flask app
CMD ["python", "app.py"]
