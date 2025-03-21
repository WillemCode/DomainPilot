# DomainPilot

**DomainPilot** は、ドメインの SSL 証明書管理を自動化する Bash スクリプトベースのツールです。阿里云（Aliyun）や華為雲（Huawei Cloud）などのクラウド DNS サービスを統合し、ドメイン所有権を検証して、SSL 証明書を自動で申請・インストールします。証明書の更新、ドメインの検証、バックアップ、キー管理などにも対応し、操作の追跡が容易になるようにログ記録とエラー処理が備わっています。

## 機能

- **自動化された SSL 証明書管理**: ドメインの SSL 証明書の申請および更新を自動化します。
- **クラウド DNS API 統合**: 阿里云と華為雲の DNS を通じて証明書申請の DNS 検証をサポートします。
- **バックアップとログ**: 設定ファイルのバックアップを自動化し、すべての操作ログを記録します。
- **キー管理**: ドメイン検証のためのクラウド DNS API 資格情報を簡単に追加および削除できます。
- **柔軟な設定**: 単一または複数のドメインを管理できます。
- **スケジュールタスク**: 証明書の有効期限を自動でチェックし、更新をリクエストします。

## 必要条件

- Nginx Web サーバー
- Bash シェル（ほとんどの Linux ディストリビューションに対応）
- ACME.sh（SSL 証明書管理用）
- クラウド DNS アカウント（Aliyun または Huawei Cloud、DNS 検証用）

## インストール

1. `DomainPilot.sh` スクリプトをクローンまたはダウンロードします。
2. システムに Nginx がインストールされ、実行中であることを確認します。
3. 必要な依存関係（ACME.sh）をインストールします：

   ```bash
   curl -s https://get.acme.sh | sh -s email=my@example.com
   ```

4. スクリプトを実行可能にし、必要な設定を行います：

   ```bash
   chmod +x DomainPilot.sh
   ./DomainPilot.sh --add
   ```

## 使用方法

### コマンドラインオプション

- `-h`, `--help`: ヘルプ情報を表示
- `-v`, `--version`: 現在のスクリプトバージョンを表示
- `-e`, `--exec`: ドメイン証明書の有効期限をチェックし、自動で更新をリクエスト
- `-l`, `--list`: 設定されているすべてのドメインと証明書情報を表示
- `-d`, `--del`: 既存のクラウド API キーを削除
- `-a`, `--add`: 新しいクラウド API キーを追加し、ドメイン所有権を検証
- `-s`, `--specify`: 特定のドメインの証明書管理を指定

### 使用例

証明書の有効期限を確認し、自動で更新を申請する：

```bash
./DomainPilot.sh --exec
```

すべてのドメインと証明書情報を一覧表示：

```bash
./DomainPilot.sh --list
```

新しいクラウド DNS API キーを追加：

```bash
./DomainPilot.sh --add
```

クラウド DNS API キーを削除：

```bash
./DomainPilot.sh --del
```

## 設定

### ドメイン設定

スクリプトは Nginx の設定ファイルを解析して、ドメインと対応する SSL 証明書を自動で検出します。解析結果は `$PROJECT_NAME.config` ファイルに保存され、その後の証明書管理に使用されます。

### クラウド DNS キー

`--add` オプションを使用して、阿里云または華為雲の DNS サービス API キーを追加できます。これらのキーは `secret.config` ファイルに暗号化形式で保存されます。

### バックアップ

スクリプトを実行するたびに、バックアップディレクトリとログファイルが自動的に作成されます。古いログやバックアップは設定に基づいて定期的に削除されます。

### ログ

すべてのスクリプト出力は、タイムスタンプ付きのログファイルに記録され、`$PROJECT_LOGS_PATH` ディレクトリに保存されます。

## スクリプトのワークフロー

1. **初期化**: Nginx 設定ファイルパス、オペレーティングシステム情報などの確認と初期化
2. **証明書の申請および更新**: 自動的に証明書が期限切れになる前に検出し、更新リクエストを行います。証明書が期限切れの場合、指定された DNS API を使用して更新を試みます。
3. **ログ記録**: すべての操作を記録し、後で確認できるようにします。
4. **スケジュールタスク**: cron ジョブを使用して証明書の確認と更新を定期的に実行します。

---

## 技術サポート

- **問題報告**: [GitHub リポジトリ](https://github.com/WillemCode/DomainPilot/issues)で Issue を提出してください。

---

## ライセンス

このプロジェクトは [GNU General Public License (GPL)](./LICENSE) の下で公開されています。

これにより：

- このプロジェクトのソースコードを自由にコピー、修正、配布できますが、変更されたプロジェクトも GPL または互換性のあるライセンスで公開する必要があります；
- 配布または公開時には、元の著作権表示と GPL 契約書を含め、完全なソースコードへのアクセス方法を提供する必要があります。

詳細な条項については [LICENSE](./LICENSE) ファイルをご覧ください。GPL の使用と遵守に関する質問がある場合は、[GNU のウェブサイト](https://www.gnu.org/licenses/) を参照するか、専門家に相談してください。

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=WillemCode/DomainPilot&type=Date)](https://www.star-history.com/#WillemCode/DomainPilot&Date)
