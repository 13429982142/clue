# 商务线索挖掘与转化智能体 (PRD v1.0) 生产部署说明

本项目已经根据您的技术栈需求（**前端 Vue 3 + 后端 Python FastAPI/Java + 数据库 MySQL 8 & Redis + Docker 容器化部署**）生成了对应的全套生产级配置文件及核心源码，存放在当前目录中。

---

## 📁 部署文件清单与架构

- `./docker-compose.yml` : 统一编排并编织前端、后端、MySQL、Redis 容器容器组。
- `./db_schema.sql` : 完整的 MySQL 8.0 物理结构表，包括线索表、评分体系表、标本大纲表及审核日志追踪表。
- `./backend/Dockerfile` : Python 3.10 FastAPI 生产发布底座配置。
- `./backend/main.py` : Python 核心后端。集成 SQLAlchemy ORM 连接池及 Redis 定时采掘任务锁，支持真实的 Gemini AI 网监线索生成、全通道分级计算、以及合同/标书 AI 生成！
- `./frontend/Dockerfile` : Vue 3 生产级多阶段构建与 Nginx 反向代理配置。

---

## 🚀 启动指引 (Docker 一键启动)

在生产或测试服务器中，确立装配有 `Docker` 和 `docker-compose` 之后，在根目录执行：

```bash
# 拷贝 env 环境变量设置 (并填写您的 )
cp .env

# 一键编译并后台启动所有微服务
docker-compose up -d --build
```

系统会自行拉取环境并映射如下端口：
- **前端 Vue3 界面**：`http://localhost:8080` (通过 Nginx 托管)
- **后端 FastAPI 接口**：`http://localhost:8000/docs` (Swagger 交互式文档)
- **MySQL 8 数据库**：`3306`
- **Redis 缓存容器**：`6379`
