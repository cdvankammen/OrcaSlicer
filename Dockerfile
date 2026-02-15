FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    gettext \
    libgtk-3-dev \
    libwxgtk3.0-gtk3-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libglu1-mesa-dev \
    libdbus-1-dev \
    extra-cmake-modules \
    pkgconf \
    libudev-dev \
    libglew-dev \
    libhidapi-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy project files
COPY . /build/

# Build dependencies
RUN cd deps && \
    mkdir -p build && \
    cd build && \
    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    ninja

# Build OrcaSlicer
RUN mkdir -p build && \
    cd build && \
    cmake .. -G Ninja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DSLIC3R_STATIC=ON \
        -DSLIC3R_GUI=ON \
        -DSLIC3R_PCH=OFF && \
    ninja

# Set entrypoint
WORKDIR /build/build
CMD ["./src/orcaslicer", "--help"]
