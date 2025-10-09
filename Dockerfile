# syntax=docker/dockerfile:1

# Option 1. USE AN OFFICIAL ROGUE CONTAINER
#FROM ghcr.io/slaclab/rogue:v6.6.2

# Option 2. USE A CONDA ENV WITH A TAGGED ROGUE RELEASE

# Option 3. USE A ROGUE DEV BRANCH (THIS WORKS FOR NOW)

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
    libbz2-dev \
    libzmq3-dev \
    python3-pyqt5 \
    python3-pyqt5.qtsvg \
    libreadline6-dev \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /assert-app

# Add GitHub to known hosts
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    ssh-keyscan -H github.com >> /root/.ssh/known_hosts

# Copy SSH private key (you'll need to provide this when building)
# Note: You'll need to have your SSH private key available during build
#COPY id_rsa /root/.ssh/id_rsa
#RUN chmod 600 /root/.ssh/id_rsa

# Clone turpial-dev (main/master branch)
#RUN git clone https://github.com/slaclab/turpial-dev.git
#RUN git clone --recursive git@github.com:slaclab/turpial-dev.git

# Clone specific branch of rogue repository
# Replace 'development-branch-name' with the actual branch name
#RUN git clone -b pre-release https://github.com/slaclab/rogue.git

# Alternative: Clone specific branch with single-branch option (saves space)
#RUN git clone -b pre-release --single-branch https://github.com/slaclab/rogue.git
#RUN git clone -b pre-release --single-branch git@github.com:slaclab/rogue.git

# Set working directory to the application root
WORKDIR /assert-app

ENV CONDA_ROGUE_ENV=assert_rogue

# Copy over the controls software
COPY rogue/ rogue/
COPY turpial-dev/ turpial-dev/
COPY .git/modules/ .git/modules/

# Install Python dependencies if requirements files exist
RUN if [ -f turpial-dev/pip_requirements.txt ]; then \
        pip3 install -r turpial-dev/pip_requirements.txt; \
    fi

RUN if [ -f rogue/pip_requirements.txt ]; then \
        pip3 install -r rogue/pip_requirements.txt; \
    fi

# Install miniforge conda
RUN wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
RUN /bin/bash Miniforge3-Linux-x86_64.sh -b -p /miniforge3

# Configure miniforge conda
# Create rogue conda environment
# Activate rogue conda environment
# Build rogue inside conda environment 
RUN . /miniforge3/etc/profile.d/conda.sh &&\
    conda config --set channel_priority strict  &&\
    conda install -n base conda-libmamba-solver &&\
    conda config --set solver libmamba &&\
    conda activate &&\
    conda update -n base -c conda-forge conda &&\
    cd /assert-app/rogue &&\
    conda env create -n $CONDA_ROGUE_ENV -f conda.yml &&\
    conda activate $CONDA_ROGUE_ENV &&\
    mkdir build &&\
    cd build &&\
    cmake .. &&\
    make &&\
    make install

ENV PATH=/miniforge3/envs/$CONDA_ROGUE_ENV/bin:$PATH

RUN echo >> ~/.bashrc
RUN echo "source /miniforge3/etc/profile.d/conda.sh" >> ~/.bashrc
RUN echo "conda activate $CONDA_ROGUE_ENV" >> ~/.bashrc

# Expose common ports (adjust as needed)
EXPOSE 8080 8000

WORKDIR /

# Set the default command
CMD ["/bin/bash"]
