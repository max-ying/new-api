# new-api 本地镜像构建与部署

这个目录用于从当前仓库源码构建 Docker 镜像，并在本机部署运行。

## 前置条件

- 已安装 Docker 和 Docker Compose v2
- 能访问 `docker.m.daocloud.io`、`goproxy.cn`、`registry.npmmirror.com`

如果这些国内源不可用，可以在 `build/.env` 中改成自己的可用地址。

## 快速启动

```sh
./build/deploy.sh deploy
```

首次运行时会自动执行：

1. 复制 `build/.env.example` 为 `build/.env`
2. 从仓库根目录的 `Dockerfile` 构建镜像
3. 启动 `new-api-build` 容器

启动完成后访问：

```text
http://127.0.0.1:3001
```

默认只绑定本机回环地址，不会暴露到局域网。

## 镜像和版本

默认镜像仓库地址是 `new-api`，版本号由 `NEW_API_VERSION` 决定。

如果 `NEW_API_VERSION` 为空，`./build/deploy.sh deploy` 会自动使用：

```sh
git describe --tags --always --dirty
```

无法获取 Git 信息时使用 `dev`。

手动设置版本：

```sh
./build/set-version.sh v1.0.0
./build/deploy.sh deploy
```

也可以直接修改 `build/.env`：

```env
NEW_API_IMAGE=my-registry.example.com/new-api
NEW_API_VERSION=v1.0.0
```

镜像会包含以下标签：

- `org.opencontainers.image.version`
- `org.opencontainers.image.revision`
- `org.opencontainers.image.created`
- `org.opencontainers.image.source`

## 国内构建源

默认配置：

```env
BUN_IMAGE=docker.m.daocloud.io/oven/bun:...
GO_IMAGE=docker.m.daocloud.io/library/golang:...
RUNTIME_IMAGE=docker.m.daocloud.io/library/debian:...
GO_PROXY=https://goproxy.cn,direct
NPM_CONFIG_REGISTRY=https://registry.npmmirror.com
```

如需恢复官方源，可改成：

```env
BUN_IMAGE=oven/bun:1.4.0
GO_IMAGE=golang:1.26.1-alpine
RUNTIME_IMAGE=debian:bookworm-slim
GO_PROXY=https://proxy.golang.org,direct
NPM_CONFIG_REGISTRY=https://registry.npmjs.org
```

## 配置文件

`build/.env` 是实际使用的配置文件，默认被 Git 忽略。

常用配置：

```env
NEW_API_IMAGE=new-api
NEW_API_VERSION=
GIT_COMMIT=
BUILD_DATE=
SOURCE_URL=
NEW_API_BIND=127.0.0.1
NEW_API_PORT=3001
TZ=Asia/Shanghai
```

`GIT_COMMIT`、`BUILD_DATE`、`SOURCE_URL` 留空时，会自动从当前 Git 仓库和系统时间生成。

应用运行参数也写在同一个文件里，例如：

```env
SQL_DSN=postgresql://user:password@host:5432/new-api
REDIS_CONN_STRING=redis://default:password@host:6379
```

默认不配置数据库和 Redis 时，应用使用 SQLite。

## 数据和日志

默认使用 Docker 命名卷：

- `new-api-build_new-api-data`：SQLite 数据和上传数据
- `new-api-build_new-api-logs`：应用日志

删除容器不会删除这些数据。

## 常用命令

查看状态：

```sh
./build/deploy.sh status
```

查看日志：

```sh
./build/deploy.sh logs
```

强制重新构建并启动：

```sh
./build/deploy.sh rebuild

重启服务：

```sh
./build/deploy.sh restart
```
```

停止服务：

```sh
./build/deploy.sh stop
```

停止并删除容器：

```sh
./build/deploy.sh down
```

清空 SQLite 数据、日志，并删除容器：

```sh
./build/deploy.sh reset-data
```

## 安全设置

默认启用：

- 只绑定 `127.0.0.1`
- `read_only: true`
- `cap_drop: [ALL]`
- `no-new-privileges:true`
- 健康检查

如果应用启动失败，可先查看日志：

```sh
./build/deploy.sh logs
```
