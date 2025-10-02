## Option 1. USE OFFICIAL ROGUE CONTAINER
#FROM ghcr.io/slaclab/rogue:v6.6.2

## Option 2. USE CONDA ENV FOR TAGGED ROGUE RELEASE

## Option 3. USE ROGUE DEV BRANCH (SELECTED FOR NOW)

# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update package list and install essential packages
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    git \
    openssh-client \
    ca-certificates \
    curl \
    wget \
    build-essential \
    python3 \
    python3-pip \
    python3-dev \
    make \
    cmake \
    libboost-all-dev \
    libbz2-dev \
    libzmq3-dev \
    python3-pyqt5 \
    python3-pyqt5.qtsvg \
    libreadline6-dev \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /app

# Add GitHub to known hosts
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    ssh-keyscan -H github.com >> /root/.ssh/known_hosts

# Clone turpial-dev (main/master branch)
RUN git clone https://github.com/slaclab/turpial-dev.git

# Clone specific branch of rogue repository
# Replace 'development-branch-name' with the actual branch name
#RUN git clone -b pre-release https://github.com/slaclab/rogue.git

# Alternative: Clone specific branch with single-branch option (saves space)
RUN git clone -b pre-release --single-branch https://github.com/slaclab/rogue.git

# Set working directory to the application root
WORKDIR /app

# Install Python dependencies if requirements files exist
RUN if [ -f turpial-dev/pip_requirements.txt ]; then \
        pip3 install -r turpial-dev/pip_requirements.txt; \
    fi

RUN if [ -f rogue/pip_requirements.txt ]; then \
        pip3 install -r rogue/pip_requirements.txt; \
    fi

# Install miniforge conda
RUN wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh && /bin/bash Miniforge3-Linux-x86_64.sh -b -p /opt/Miniforge3 && source /opt/Miniforge3/etc/profile.d/conda.sh

# Configure miniforge conda
RUN conda config --set channel_priority strict &&\
    conda install -n base conda-libmamba-solver &&\
    conda config --set solver libmamba

# Create rogue conda environment
RUN cd rogue &&\
    conda activate &&\
    conda env create -n assert_rogue -f conda.yml

# Activate rogue conda environment
RUN conda activate assert_rogue

# Build rogue inside conda environment 
RUN mkdir build &&\
    cd build &&\
    cmake .. &&\
    make &&\
    make install

# Set working directory to the application root
WORKDIR /app

# Expose common ports (adjust as needed)
EXPOSE 8080 8000

# Set the default command
CMD ["/bin/bash"]
