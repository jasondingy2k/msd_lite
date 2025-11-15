# ----------------------------------------------------
# 阶段 1: 编译阶段 (Build Stage) - 基于 Alpine Linux
# ----------------------------------------------------
FROM alpine:latest AS builder

# 安装编译工具链：
RUN apk update && apk add --no-cache \
    build-base \
    cmake \
    git \
    cunit-dev \
    musl-dev \
    bsd-compat-headers

WORKDIR /app
# 复制 msd_lite 代码
COPY . /app

# --- CMake 编译步骤 ---
# 1. 创建并进入 build 目录
RUN cmake -E make_directory /app/build
WORKDIR /app/build

# 2. 配置 CMake
RUN cmake /app -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-static -s" -DCMAKE_CXX_FLAGS="-static -s"

# 3. 构建程序
RUN cmake --build . --config Release

# ----------------------------------------------------
# 阶段 2: 运行阶段 (Runtime Stage) - 使用极简 Alpine
# ----------------------------------------------------
FROM alpine:latest

# 设定 msd_lite 程序运行目录
WORKDIR /usr/local/bin

# 从编译阶段复制编译好的二进制文件
# 修正：路径改为 /app/build/src/msd_lite
COPY --from=builder /app/build/src/msd_lite .
# 复制修改后的配置文件 (端口 8016) 到 /etc 目录
COPY --from=builder /app/conf/msd_lite.conf /etc/msd_lite.conf

# 声明容器内部监听的端口 (8016)
EXPOSE 8016

# 启动 msd_lite 程序，使用修改后的配置文件。
CMD ["./msd_lite", "-c", "/etc/msd_lite.conf"]
