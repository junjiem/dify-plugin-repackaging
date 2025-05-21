# Base image Ubuntu 24.04
FROM ubuntu:24.04

# Set environment variables to prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update &&     apt-get install -y --no-install-recommends     curl     unzip     python3     python3-pip &&     rm -rf /var/lib/apt/lists/*

# Copy plugin packager binaries
COPY dify-plugin-linux-amd64-5g /usr/local/bin/dify-plugin-linux-amd64-5g
COPY dify-plugin-linux-arm64-5g /usr/local/bin/dify-plugin-linux-arm64-5g

# Create app directory and copy scripts
WORKDIR /app
COPY plugin_repackaging.sh .
# entrypoint.sh will be created in a later step, but we define its copy operation here
COPY entrypoint.sh .

# Ensure scripts are executable (permissions will be set more formally on the scripts themselves,
# but this is a common practice if COPY --chmod is not used or for clarity)
# RUN chmod +x plugin_repackaging.sh entrypoint.sh

# The entrypoint will be set in docker-compose.yml or explicitly when running docker run
# For now, we just ensure the files are in place.
