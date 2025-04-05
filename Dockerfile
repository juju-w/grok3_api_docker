# ---- Stage 1: Build ----
# 使用官方 Go 镜像作为构建环境
# 选择一个具体的版本，例如 1.22 (根据你的 go.mod 调整)
# 使用 alpine 版本以减小基础镜像大小
FROM docker.1ms.run/golang:1.24-alpine AS builder

# 设置工作目录
WORKDIR /app

# 预拷贝 go.mod 和 go.sum 文件以利用 Docker 缓存
COPY go.mod go.sum ./

# 下载依赖项
# 使用 -buildvcs=false 避免 Git 相关错误（如果你的环境没有 Git）
# 在某些网络环境下可能需要设置代理
# RUN export GOPROXY=https://goproxy.cn,direct && go mod download -buildvcs=false
RUN go mod tidy

# 拷贝所有源代码
COPY . .

# 构建 Go 应用
# CGO_ENABLED=0: 禁用 CGo，生成静态链接的二进制文件，减少对系统库的依赖
# GOOS=linux: 确保为 Linux 系统构建
# -ldflags '-w -s': 减小二进制文件大小 (-w 去除调试信息, -s 去除符号表)
# -o /app/grok3-adapter: 指定输出文件名和路径
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/grok3-adapter main.go

# ---- Stage 2: Runtime ----
# 使用一个非常小的基础镜像，例如 alpine
FROM docker.1ms.run/alpine:latest

# 设置工作目录
WORKDIR /app

# 从构建阶段拷贝编译好的二进制文件
COPY --from=builder /app/grok3-adapter /app/grok3-adapter

# Alpine 默认可能缺少根证书，这对于发出 HTTPS 请求是必需的
# 如果你的程序需要连接 https://grok.com，请确保安装了 ca-certificates
# RUN apk --no-cache add ca-certificates

# 设置默认环境变量 (这些可以在 docker-compose.yml 中覆盖)
# 注意：Go flag 库默认不直接读取环境变量，除非代码中显式处理
# 但 GROK3_AUTH_TOKEN 和 GROK3_COOKIE 是特例，代码中有 os.Getenv 读取
ENV GROK3_AUTH_TOKEN=""
ENV GROK3_COOKIE=""
# 其他参数的默认值最好通过 CMD 或 docker-compose command 设置
ENV PORT=8180
# 其他 Go flags 的默认值将在 CMD 中体现

# 暴露应用程序监听的端口 (默认 8180)
# 使用 ARG 和 ENV 结合，允许在构建时或运行时覆盖端口
ARG PORT=8180
ENV PORT=${PORT}
EXPOSE ${PORT}

# 设置容器启动时执行的命令
# ENTRYPOINT 使用可执行文件
ENTRYPOINT ["/app/grok3-adapter"]

# CMD 提供 ENTRYPOINT 的默认参数
# 这些参数对应 Go 代码中的 flag
# 将配置放在这里或 docker-compose.yml 的 command 部分
CMD [ \
    "-port=${PORT}", \
    "-token=${GROK3_AUTH_TOKEN}", \
    "-cookie=${GROK3_COOKIE}" \
    # 其他 flag 可以在 docker-compose.yml 中根据需要添加
    # 例如: "-keepChat=false", "-ignoreThinking=false", "-charsLimit=50000"
]
