# DomainPilot

**DomainPilot** is a Bash script-based tool for automating the management of SSL certificates for domains. It integrates with cloud DNS services (such as Aliyun and Huawei Cloud) to validate domain ownership, automatically request and install SSL certificates. The script also supports certificate renewal, domain validation, backups, and key management, with logging and error handling for easy operation tracking.

## Features

- **Automated SSL Certificate Management**: Automatically manages SSL certificate applications and renewals for domains.
- **Cloud DNS API Integration**: Supports DNS validation for certificate requests via Aliyun and Huawei Cloud DNS.
- **Backup and Logs**: Automatically backs up configuration files and records all operation logs.
- **Key Management**: Conveniently adds and deletes cloud DNS API credentials for domain validation.
- **Flexible Configuration**: Supports certificate management for single or multiple domains.
- **Scheduled Tasks**: Automatically checks certificate expiration and requests renewals.

## Requirements

- Nginx Web Server
- Bash Shell (supports most Linux distributions)
- ACME.sh (for SSL certificate management)
- Cloud DNS account (Aliyun or Huawei Cloud, for DNS validation)

## Installation

1. Clone or download the `DomainPilot.sh` script.
2. Ensure that Nginx is installed and running on your system.
3. Install required dependencies (ACME.sh for certificate management):

   ```bash
   curl -s https://get.acme.sh | sh -s email=my@example.com
   ```

4. Set the script as executable and configure the necessary settings:

   ```bash
   chmod +x DomainPilot.sh
   ./DomainPilot.sh --add
   ```

## Usage

### Command-Line Options

- `-h`, `--help`: Display help information.
- `-v`, `--version`: Display the current script version.
- `-e`, `--exec`: Check domain certificate expiration and automatically request renewal.
- `-l`, `--list`: List all configured domains and certificate details.
- `-d`, `--del`: Delete an existing cloud API key.
- `-a`, `--add`: Add a new cloud API key and validate domain ownership.
- `-s`, `--specify`: Specify a single domain for certificate management.

### Example Usage

Check and automatically request certificates that are about to expire:

```bash
./DomainPilot.sh --exec
```

List all configured domains and their certificate information:

```bash
./DomainPilot.sh --list
```

Add a new cloud DNS API key:

```bash
./DomainPilot.sh --add
```

Delete a cloud DNS API key:

```bash
./DomainPilot.sh --del
```

## Configuration

### Domain Configuration

The script parses your Nginx configuration file to automatically detect domains and their corresponding SSL certificates. The parsed configuration is stored in a file (`$PROJECT_NAME.config`) and is used for subsequent domain certificate management.

### Cloud DNS Keys

You can add Aliyun or Huawei Cloud DNS service API keys using the `--add` option. The keys will be stored in an encrypted form in the `secret.config` file.

### Backup

Each time the script runs, backup directories and log files are automatically created. Old logs and backups will be periodically cleaned based on the configuration.

### Logs

All script outputs are logged in a timestamped log file located in the `$PROJECT_LOGS_PATH` directory.

## Script Workflow

1. **Initialization**: Checks and initializes the Nginx configuration file path, operating system information, etc.
2. **Certificate Application and Renewal**: Automatically detects if certificates are about to expire and requests renewals. If the certificate has expired, the script will attempt to renew it using the specified DNS API.
3. **Log Recording**: Logs each operation for future reference.
4. **Scheduled Tasks**: Executes certificate checks and renewals via cron jobs.

---

## Technical Support

- **Issue Reporting**: Please submit an issue at the [GitHub Repository](https://github.com/WillemCode/DomainPilot/issues).

---

## License

This project is released under the [GNU General Public License (GPL)](./LICENSE).

This means:

- You are free to copy, modify, and distribute the source code of this project, but the modified project must also be released under the GPL or a compatible license;
- When distributing or publishing, you must include the original copyright notice and the GPL agreement text, and provide access to the full source code.

Please refer to the [LICENSE](./LICENSE) file for detailed terms. If you have any questions about the use and compliance of the GPL, please consult [GNU's website](https://www.gnu.org/licenses/) or seek professional advice.

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=WillemCode/DomainPilot&type=Date)](https://www.star-history.com/#WillemCode/DomainPilot&Date)
