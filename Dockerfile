FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/python:3.12-slim

# 设置apt国内源
RUN echo "deb https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list

# 安装必要的工具 (包括 uv)
RUN apt-get update && \
    apt-get install -y curl unzip && \
    # --- 新增：安装 uv ---
    # 方法1：使用官方脚本安装到 /usr/local/bin (推荐，速度最快)
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    # 确保 uv 在 PATH 中 (通常脚本会自动处理，但显式确认更安全)
    export PATH="/root/.local/bin:$PATH" && \
    # 验证安装
    uv --version && \
    # ------------------
    rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制所有文件到容器中
COPY . .

# 给脚本添加执行权限
RUN chmod +x plugin_repackaging.sh

# 设置默认命令
CMD ["./plugin_repackaging.sh", "-p", "manylinux_2_17_x86_64", "market", "antv", "visualization", "0.1.7"]
