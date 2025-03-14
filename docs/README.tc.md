# DomainPilot

**DomainPilot** 是一個基於 Bash 腳本的工具，用於自動化管理網域的 SSL 憑證。該工具通過集成雲 DNS 服務（如阿里雲、華為雲）進行網域驗證，自動申請並安裝 SSL 憑證。腳本還支持憑證續期、網域驗證、備份和密鑰管理等功能，並具備日誌記錄和錯誤處理功能，方便追蹤操作。

## 功能

- **自動化 SSL 憑證管理**：自動化管理網域的 SSL 憑證申請與續期。
- **雲 DNS API 集成**：支持通過阿里雲和華為雲 DNS 進行憑證申請的 DNS 驗證。
- **備份與日誌**：自動備份配置文件並記錄所有操作日誌。
- **密鑰管理**：方便地添加和刪除雲 DNS API 憑證進行網域驗證。
- **靈活配置**：支持對單一或多個網域進行憑證管理。
- **定時任務設置**：自動檢查憑證到期情況，並申請續期。

## 環境要求

- Nginx Web 伺服器
- Bash Shell（支持大多數 Linux 發行版）
- ACME.sh（用於 SSL 憑證管理）
- 雲 DNS 帳號（阿里雲或華為雲，用於 DNS 驗證）

## 安裝

1. 克隆或下載 `DomainPilot.sh` 腳本。
2. 確保系統已安裝並運行 Nginx。
3. 安裝所需的依賴（ACME.sh 用於憑證管理）：

   ```bash
   curl -s https://get.acme.sh | sh -s email=my@example.com
   ```

4. 設置腳本為可執行並配置所需的設置：

   ```bash
   chmod +x DomainPilot.sh
   ./DomainPilot.sh --add
   ```

## 使用方法

### 命令列選項

- `-h`，`--help`：顯示幫助資訊。
- `-v`，`--version`：顯示當前腳本版本。
- `-e`，`--exec`：檢查網域憑證到期情況，並自動申請續期。
- `-l`，`--list`：列出所有配置的網域及憑證資訊。
- `-d`，`--del`：刪除已有的雲端 API 密鑰。
- `-a`，`--add`：添加新的雲端 API 密鑰並驗證網域所有權。
- `-s`，`--specify`：指定單一網域進行憑證管理。

### 使用範例

檢查並自動申請即將到期的憑證：

```bash
./DomainPilot.sh --exec
```

列出所有配置的網域及其憑證資訊：

```bash
./DomainPilot.sh --list
```

添加新的雲 DNS API 密鑰：

```bash
./DomainPilot.sh --add
```

刪除雲 DNS API 密鑰：

```bash
./DomainPilot.sh --del
```

## 配置

### 網域配置

腳本會解析您的 Nginx 配置文件，自動檢測網域和對應的 SSL 憑證。解析後的配置存儲在文件中（`$PROJECT_NAME.config`），並用於後續的網域憑證管理。

### 雲 DNS 密鑰

您可以通過 `--add` 選項添加阿里雲或華為雲的 DNS 服務 API 密鑰。密鑰會以加密形式存儲在 `secret.config` 文件中。

### 備份

每次運行腳本時，會自動創建備份目錄和日誌文件。舊的日誌和備份會根據配置定期清理。

### 日誌

所有腳本輸出都會被記錄到一個以時間戳命名的日誌文件中，存放在 `$PROJECT_LOGS_PATH` 目錄下。

## 腳本功能流程

1. **初始化操作**：檢查並初始化 Nginx 配置文件路徑、操作系統資訊等。
2. **憑證申請與續期**：自動檢測憑證是否即將過期，並進行續期申請。如果憑證已經過期，腳本會嘗試使用指定的 DNS API 進行續期。
3. **日誌記錄**：每個操作的日誌都會被記錄，方便後續查看。
4. **定時任務**：透過 cron job 定期執行憑證檢查和續期操作。

---

## 技術支持

- **問題反饋**：請提交 Issue 至 [GitHub 倉庫](https://github.com/WillemCode/ScriptTools/issues)。

---

## 授權聲明

本專案採用 [GNU General Public License (GPL)](./LICENSE) 開源發布。

這意味著：

- 您可以自由複製、修改和發佈本專案的源代碼，但修改後的專案也必須繼續以 GPL 或兼容的許可證進行發布；
- 發佈或發佈時，需包含本專案的原始版權聲明與 GPL 協議文本，並提供完整的源代碼獲取方式。

請參閱 [LICENSE](./LICENSE) 文件獲取詳細條款。若您對 GPL 的使用及合規性有任何疑問，請查閱 [GNU 官網](https://www.gnu.org/licenses/) 或諮詢相關專業人士。

---

## Star 歷史

[![Star History Chart](https://api.star-history.com/svg?repos=WillemCode/DomainPilot&type=Date)](https://www.star-history.com/#WillemCode/DomainPilot&Date)
```
