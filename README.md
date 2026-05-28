# SnapTask

SnapTask 是一个面向课程任务管理的 HarmonyOS 应用，支持截图 OCR、DeepSeek 解析、Todo 管理、已完成历史归档和横屏适配。

## 仓库结构

- `entry/` HarmonyOS 前端
- `backend/` Spring Boot 后端

## 前端运行

1. 用 DevEco Studio 打开仓库根目录。
2. 运行 `entry` 模块到平板或手机。
3. 如需连接后端，请把 `entry/src/main/ets/api/SnapTaskApi.ets` 里的 `baseUrl` 改成电脑的局域网地址。

## 后端运行

1. 安装 JDK 17 和 MySQL。
2. 创建数据库 `snaptask_db`，执行 `backend/src/main/resources/snaptask_schema.sql`。
3. 配置环境变量：

```bash
MYSQL_URL=jdbc:mysql://localhost:3306/snaptask_db?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
MYSQL_USERNAME=root
MYSQL_PASSWORD=你的密码
DEEPSEEK_API_KEY=你的Key
```

4. 进入 `backend/`，执行：

```bash
mvn spring-boot:run
```

## 提交说明

- 前端构建产物、`oh_modules`、`build`、`.hvigor`、后端 `target`、日志文件不会提交到仓库。
- 数据库脚本、前后端源码和说明文档会保留。
