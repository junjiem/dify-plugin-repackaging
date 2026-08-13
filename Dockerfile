FROM python:3.12-slim

# 设置apt国内源
RUN echo "deb https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list

# 安装必要的工具
RUN apt-get update && \
    apt-get install -y curl unzip && \
    rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制所有文件到容器中
COPY . .

# 给脚本添加执行权限
RUN chmod +x plugin_repackaging.sh

# 设置默认命令
CMD ["./plugin_repackaging.sh", "-p", "manylinux_2_28_aarch64", "market", "langgenius", "openai_api_compatible", "0.0.59"]
