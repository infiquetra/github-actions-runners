# Custom GitHub Actions Runner Image
# Pre-installed: Python 3.12, Dart, Flutter, AWS CLI, Node.js 20
#
# Based on the official GitHub Actions runner image

FROM ghcr.io/actions/actions-runner:latest

# Metadata
LABEL org.opencontainers.image.source="https://github.com/infiquetra/github-actions-runners"
LABEL org.opencontainers.image.description="Custom GitHub Actions runner with Python, Dart, Flutter, and AWS CLI"

# Switch to root for package installation
USER root

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ============================================
# System Dependencies
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    jq \
    unzip \
    zip \
    gnupg \
    lsb-release \
    software-properties-common \
    ca-certificates \
    build-essential \
    sudo \
    xz-utils \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Add runner user to sudoers (passwordless) for tool installation
RUN echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ============================================
# Python 3.12+ Installation
# ============================================
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.12 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

# Install pip for Python 3.12
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12

# Install uv (fast Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# ============================================
# AWS CLI v2 Installation
# ============================================
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# ============================================
# Node.js 20 LTS Installation
# ============================================
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# Dart SDK Installation
# ============================================
RUN wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | \
    tee /etc/apt/sources.list.d/dart_stable.list && \
    apt-get update && \
    apt-get install -y dart && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="$PATH:/usr/lib/dart/bin"

# ============================================
# Flutter SDK Installation
# ============================================
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

# Clone Flutter and checkout stable channel
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FLUTTER_HOME && \
    flutter precache --linux --web && \
    flutter config --no-analytics

# ============================================
# Additional Flutter Dependencies (for Linux builds)
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# Cleanup
# ============================================
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ============================================
# Setup for runner user
# ============================================
USER runner

# Set up uv for runner user
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/runner/.local/bin:$PATH"

# Pre-accept Flutter licenses (run as runner user)
RUN yes | flutter doctor --android-licenses 2>/dev/null || true

# Configure Flutter for runner user
RUN flutter config --no-analytics && \
    flutter doctor

# ============================================
# Verification
# ============================================
RUN echo "=== Verifying installations ===" && \
    python3 --version && \
    pip3 --version && \
    uv --version && \
    dart --version && \
    flutter --version && \
    aws --version && \
    node --version && \
    npm --version && \
    echo "=== All tools installed successfully ==="

WORKDIR /home/runner
