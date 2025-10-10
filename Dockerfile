# syntax=docker/dockerfile:1

# Option 1. USE AN OFFICIAL ROGUE CONTAINER
#FROM ghcr.io/slaclab/rogue:v6.6.2

# Option 2. USE A CONDA ENV WITH A TAGGED ROGUE RELEASE

# Option 3. USE A ROGUE DEV BRANCH (THIS IS BEST FOR NOW)

# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

USER root

ARG uid
ARG gid
ARG user

RUN groupadd -g ${gid} -o ${user}
RUN useradd -m -N --gid ${gid} --shell /bin/bash --uid ${uid} ${user}

# Update package list and install essential packages
RUN apt-get update && apt-get install -y \
    vim \
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
    libxcb-xinerama0 \
    libxcb-util1 \
    libxkbcommon-x11-0 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-icccm4 \
    x11-apps \
    && apt-get clean && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# Create the following directory 
RUN mkdir -p /run/user/${uid}
RUN chown -R ${uid}:${gid} /run/user/${uid}
RUN chmod -R 700 /run/user/${uid}

# Create a working directory
WORKDIR /home/${user}/assert-app

ENV CONDA_ROGUE_ENV=assert_rogue

# Copy over the controls software
COPY rogue/ rogue/
COPY turpial-dev/ turpial-dev/
COPY .git/modules/ .git/modules/

COPY start.sh start.sh
RUN chmod +x /home/${user}/assert-app/start.sh

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
    cd /home/${user}/assert-app/rogue &&\
    conda env create -n ${CONDA_ROGUE_ENV} -f conda.yml &&\
    conda activate ${CONDA_ROGUE_ENV} &&\
    mkdir build &&\
    cd build &&\
    cmake .. &&\
    make &&\
    make install

USER ${user}
WORKDIR /home/${user}

RUN echo >> /home/${user}/.bashrc
RUN echo "source /miniforge3/etc/profile.d/conda.sh" >> ~/.bashrc
RUN echo "conda activate ${CONDA_ROGUE_ENV}" >> ~/.bashrc

ENV PATH=/miniforge3/envs/${CONDA_ROGUE_ENV}/bin:$PATH
ENV XDG_RUNTIME_DIR=/run/user/${uid}

# Expose common ports (adjust as needed)
EXPOSE 9090 9099-9101

# Set new work directory
WORKDIR /home/${user}/assert-app/

# Set the default command
#CMD ["/home/${user}/assert-app/start.sh"]
CMD ["/bin/bash"]
