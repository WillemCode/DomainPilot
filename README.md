
# DomainPilot

**DomainPilot** 是一个基于 Bash 脚本的工具，用于自动化管理域名的 SSL 证书。该工具通过集成云 DNS 服务（如阿里云、华为云）进行域名验证，自动申请和安装 SSL 证书。脚本还支持证书续期、域名验证、备份和密钥管理等功能，并具备日志记录和错误处理功能，方便追踪操作。

## 功能

- **自动化 SSL 证书管理**：自动化管理域名的 SSL 证书申请与续期。
- **云 DNS API 集成**：支持通过阿里云和华为云 DNS 进行证书申请的 DNS 验证。
- **备份与日志**：自动备份配置文件并记录所有操作日志。
- **密钥管理**：方便地添加和删除云 DNS API 凭据进行域名验证。
- **灵活配置**：支持对单一或多个域名进行证书管理。
- **定时任务设置**：自动检查证书到期情况，并申请续期。

## 环境要求

- Nginx Web 服务器
- Bash Shell（支持大多数 Linux 发行版）
- ACME.sh（用于 SSL 证书管理）
- 云 DNS 账号（阿里云或华为云，用于 DNS 验证）

## 安装

1. 克隆或下载 `DomainPilot.sh` 脚本。
2. 确保系统已安装并运行 Nginx。
3. 安装所需的依赖（ACME.sh 用于证书管理）：
   
   ```bash
   curl -s https://get.acme.sh | sh -s email=my@example.com
   ```

4. 设置脚本为可执行并配置所需的设置：

   ```bash
   chmod +x DomainPilot.sh
   ./DomainPilot.sh --add
   ```

## 使用方法

### 命令行选项

- `-h`，`--help`：显示帮助信息。
- `-v`，`--version`：显示当前脚本版本。
- `-e`，`--exec`：检查域名证书到期情况，自动申请续期。
- `-l`，`--list`：列出所有配置的域名及证书信息。
- `-d`，`--del`：删除已有的云端 API 密钥。
- `-a`，`--add`：添加新的云端 API 密钥并验证域名所有权。
- `-s`，`--specify`：指定单一域名进行证书管理。

### 使用示例

检查并自动申请即将到期的证书：

```bash
./DomainPilot.sh --exec
```

列出所有配置的域名及其证书信息：

```bash
./DomainPilot.sh --list
```

添加新的云 DNS API 密钥：

```bash
./DomainPilot.sh --add
```

删除云 DNS API 密钥：

```bash
./DomainPilot.sh --del
```

## 配置

### 域名配置

脚本会解析您的 Nginx 配置文件，自动检测域名和对应的 SSL 证书。解析后的配置存储在文件中（`$PROJECT_NAME.config`），并用于后续的域名证书管理。

### 云 DNS 密钥

您可以通过 `--add` 选项添加阿里云或华为云的 DNS 服务 API 密钥。密钥会以加密形式存储在 `secret.config` 文件中。

### 备份

每次运行脚本时，都会自动创建备份目录和日志文件。旧的日志和备份会根据配置定期清理。

### 日志

所有脚本输出都会被记录到一个以时间戳命名的日志文件中，存放在 `$PROJECT_LOGS_PATH` 目录下。

## 脚本功能流程

1. **初始化操作**：检查并初始化 Nginx 配置文件路径、操作系统信息等。
2. **证书申请与续期**：自动检测证书是否即将过期，并进行续期申请。如果证书已经过期，脚本会尝试使用指定的 DNS API 进行续期。
3. **日志记录**：每个操作的日志都会被记录，以便后续查看。
4. **定时任务**：通过 cron job 定时执行证书检查和续期操作。

---

## 技术支持

- **问题反馈**：请提交Issue至[GitHub仓库](https://github.com/WillemCode/DomainPilot/issues)。

---

## 许可证说明

本项目采用 [GNU General Public License (GPL)](./LICENSE) 进行开源发布。  
这意味着：

- 你可以自由复制、修改和分发本项目的源代码，但修改后的项目也必须继续以 GPL 或兼容的许可证进行发布；
- 分发或发布时，需包含本项目的原始版权声明与 GPL 协议文本，并提供完整的源代码获取方式。

请参阅 [LICENSE](./LICENSE) 文件获取详细条款。若你对 GPL 的使用及合规性有任何疑问，请查阅 [GNU 官网](https://www.gnu.org/licenses/) 或咨询相关专业人士。

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=WillemCode/DomainPilot&type=Date)](https://www.star-history.com/#WillemCode/DomainPilot&Date)
