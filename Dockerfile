FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/python:3.12-slim

# 设置apt国内源
RUN echo "deb https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list

# 安装构建工具（关键）
RUN apt-get update && apt-get install -y \
    curl unzip dos2unix \
    gcc g++ make \
    build-essential pkg-config \
    libcairo2 libcairo2-dev \
    libpango1.0-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

# 修复 CRLF
RUN dos2unix /app/plugin_repackaging.sh && \
    chmod +x /app/plugin_repackaging.sh

ENTRYPOINT ["bash", "/app/plugin_repackaging.sh"]
