# ----------------------------------------------------
# 阶段 1: 编译阶段 (Build Stage) - 基于 Alpine Linux
# ----------------------------------------------------
# 移除 --platform 声明，依赖外部 docker build 命令指定 x86/64 架构
FROM alpine:latest AS builder

# 安装编译工具链：build-base 包含 gcc, g++, make 等
# musl-dev 用于确保静态链接
RUN apk update && apk add --no-cache \
    build-base \
    git \
    make \
    musl-dev

WORKDIR /app
# 复制 msd_lite 代码（包括你修改过的 conf/msd_lite.conf 文件）
COPY . /app

# 编译 msd_lite
# 修正：移除不存在的 'clean' target，只保留 'all'
# 使用 -static 标志进行静态链接，确保最终二进制文件不依赖运行时库
RUN make CFLAGS="-static -s" LDFLAGS="-static"

# ----------------------------------------------------
# 阶段 2: 运行阶段 (Runtime Stage) - 使用极简 Alpine
# ----------------------------------------------------
# 同样移除 --platform 声明
FROM alpine:latest

# 设定 msd_lite 程序运行目录
WORKDIR /usr/local/bin

# 从编译阶段复制编译好的二进制文件
COPY --from=builder /app/msd_lite .
# 复制修改后的配置文件 (端口 8016) 到 /etc 目录
COPY --from=builder /app/conf/msd_lite.conf /etc/msd_lite.conf

# 声明容器内部监听的端口 (8016)
EXPOSE 8016

# 启动 msd_lite 程序，使用修改后的配置文件。
CMD ["./msd_lite", "-c", "/etc/msd_lite.conf"]
