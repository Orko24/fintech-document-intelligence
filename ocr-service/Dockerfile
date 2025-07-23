FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    libopencv-dev \
    libtesseract-dev \
    tesseract-ocr \
    tesseract-ocr-eng \
    libleptonica-dev \
    libboost-all-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Crow (C++ web framework)
RUN git clone https://github.com/CrowCpp/Crow.git /tmp/crow && \
    cd /tmp/crow && \
    mkdir build && cd build && \
    cmake .. && \
    make install && \
    cd / && rm -rf /tmp/crow

# Install nlohmann/json
RUN git clone https://github.com/nlohmann/json.git /tmp/json && \
    cd /tmp/json && \
    mkdir build && cd build && \
    cmake .. && \
    make install && \
    cd / && rm -rf /tmp/json

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Create build directory and build
RUN mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc)

# Create non-root user
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app

# Create necessary directories
RUN mkdir -p /tmp/ocr_uploads && \
    chown -R app:app /tmp/ocr_uploads

# Switch to app user
USER app

# Expose port
EXPOSE 8002

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8002/health || exit 1

# Run the application
CMD ["./build/ocr-service"] 