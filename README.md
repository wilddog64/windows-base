# Windows Base

Ansible role for Windows base configuration including Chocolatey package manager, security configuration, agent installations, and WSManCredSSP setup.

## Requirements

- Ansible 2.14+
- `ansible.windows` collection
- `chocolatey.chocolatey` collection
- Target: Windows host accessible over WinRM with administrator rights

### Development Requirements

- [Vagrant](https://www.vagrantup.com/) >= 2.3
- [VirtualBox](https://www.virtualbox.org/) >= 7.0
- Ruby + Bundler (for Test Kitchen)

## Features

- **Chocolatey Setup**: Custom installation directory, environment variables, PATH configuration
- **Security Configuration**: Local group membership, folder permissions (ACLs), Windows shares
- **Agent Installations**: Splunk OTEL Collector, Nessus Agent, Seeker Agent (URL or path)
- **WSManCredSSP**: Server and client configuration for credential delegation

## Quick Start

```bash
# Setup development environment
./scripts/setup.sh all

# Run quick test with Vagrant
make vagrant-up

# Or use Make shortcuts
make test-choco      # Test Chocolatey only
make test-security   # Test security only
make test-credssp    # Test CredSSP only
```

## Role Variables

### Chocolatey Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `choco_install_dir` | `C:/choco` | Chocolatey installation directory |
| `choco_tools_dir` | `C:/choco-tools` | Chocolatey tools directory for portable apps |
| `choco_install_ps1` | `C:/Windows/Temp/choco-install.ps1` | Temporary path for install script |

### Security Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `install_drive` | `D:` | Drive for application folders |
| `security_enabled` | `true` | Enable/disable security configuration |
| `security_admin_groups` | `[]` | Groups to add to local Administrators |
| `security_service_account` | `""` | Service account for folder permissions |
| `security_jenkins_accounts` | `[...]` | Jenkins accounts for folder/share permissions |
| `security_readonly_folders` | `[...]` | Folders with ReadAndExecute permissions |
| `security_modify_folders` | `[...]` | Folders with Modify permissions |
| `security_jenkins_folders` | `[...]` | Folders with Jenkins Modify permissions |
| `security_shares` | `[...]` | Windows shares to create |

### Agent Installation Settings

Each agent supports two installation methods:
- **URL**: Downloads MSI from HTTP/HTTPS URL, then installs
- **Path**: Installs directly from local or network path (UNC)

If both URL and path are provided, URL takes precedence.

| Variable | Default | Description |
|----------|---------|-------------|
| `agents_temp_dir` | `C:/temp/agents` | Temporary directory for downloaded installers |
| `splunk_otel_enabled` | `false` | Enable Splunk OTEL Collector installation |
| `splunk_otel_installer_url` | `""` | URL to download MSI (HTTP/HTTPS) |
| `splunk_otel_installer_path` | `""` | Direct path to MSI (local or UNC) |
| `splunk_otel_product_id` | `""` | Product ID for idempotency |
| `splunk_otel_install_args` | `/quiet /norestart` | MSI install arguments |
| `nessus_enabled` | `false` | Enable Nessus Agent installation |
| `nessus_installer_url` | `""` | URL to download MSI |
| `nessus_installer_path` | `""` | Direct path to MSI |
| `nessus_product_id` | `""` | Product ID for idempotency |
| `nessus_install_args` | `/quiet /norestart` | MSI install arguments |
| `seeker_enabled` | `false` | Enable Seeker Agent installation |
| `seeker_installer_url` | `""` | URL to download MSI |
| `seeker_installer_path` | `""` | Direct path to MSI |
| `seeker_product_id` | `""` | Product ID for idempotency |
| `seeker_install_args` | `/quiet /norestart` | MSI install arguments |

### WSManCredSSP Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `credssp_enabled` | `true` | Enable WSManCredSSP configuration |
| `credssp_client_enabled` | `true` | Enable CredSSP client role |
| `credssp_delegate_computers` | `*` | Computers to delegate credentials to |

## Ansible Tags

| Tag | Description |
|-----|-------------|
| `choco` | Chocolatey setup only |
| `chocolatey` | Alias for choco |
| `security` | Security configuration only |
| `security-groups` | Local group membership only |
| `security-acl` | Folder permissions only |
| `security-shares` | Windows shares only |
| `agents` | Agent installations only |
| `agents-splunk` | Splunk OTEL only |
| `agents-nessus` | Nessus Agent only |
| `agents-seeker` | Seeker Agent only |
| `credssp` | WSManCredSSP configuration only |

## Example Playbooks

### Basic Usage

```yaml
---
- hosts: windows_servers
  roles:
    - role: windows-base
```

### Custom Chocolatey Directory

```yaml
---
- hosts: windows_servers
  roles:
    - role: windows-base
      vars:
        choco_install_dir: "D:/choco"
        choco_tools_dir: "D:/choco-tools"
```

### With Security Configuration

```yaml
---
- hosts: windows_servers
  roles:
    - role: windows-base
      vars:
        security_admin_groups:
          - "PACIFIC\\Dev-Ops Admins"
        security_service_account: "DEV\\CompassManagedServiceAccounts"
```

### Agent Installation from URL

```yaml
---
- hosts: windows_servers
  roles:
    - role: windows-base
      vars:
        splunk_otel_enabled: true
        splunk_otel_installer_url: "https://example.com/splunk-otel.msi"
        splunk_otel_product_id: "{GUID}"
        nessus_enabled: true
        nessus_installer_url: "https://example.com/nessus-agent.msi"
        nessus_product_id: "{GUID}"
```

### Agent Installation from Network Share

```yaml
---
- hosts: windows_servers
  roles:
    - role: windows-base
      vars:
        splunk_otel_enabled: true
        splunk_otel_installer_path: "\\\\fileserver\\installers\\splunk-otel.msi"
        splunk_otel_product_id: "{GUID}"
        nessus_enabled: true
        nessus_installer_path: "\\\\fileserver\\installers\\nessus-agent.msi"
        nessus_product_id: "{GUID}"
```

## Makefile Targets

Run `make help` for all available targets:

### Validation

```bash
make setup          # Verify and setup development environment
make lint           # Run ansible-lint
make syntax         # Check playbook syntax
make check          # Run all validation checks
```

### Environment Variables

The Makefile supports passing the `ADO_PAT_TOKEN` environment variable to Ansible. Export it in your terminal before running:

```bash
export ADO_PAT_TOKEN="your-secure-pat-token"
make vagrant-provision
```

If not set, it defaults to `placeholder` and relevant tasks are skipped.

### Vagrant Testing

```bash
make vagrant-up         # Start VM and provision
make vagrant-provision  # Re-provision existing VM
make vagrant-ssh        # Connect via PowerShell
make vagrant-destroy    # Destroy VM
make vagrant-status     # Show VM status

# With specific tags
make vagrant-provision TAGS=choco,security

# Use different box
make vagrant-up VAGRANT_BOX=windows11-disk
```

### Test Kitchen

```bash
make test-win11      # Full test cycle
make converge-win11  # Converge only
make verify-win11    # Verify only
make destroy-win11   # Destroy VM
make kitchen-list    # List instances
```

### Quick Test Shortcuts

```bash
make test            # Quick test (vagrant up)
make test-choco      # Test Chocolatey only
make test-security   # Test security only
make test-agents     # Test agents only
make test-credssp    # Test CredSSP only
```

### Utilities

```bash
make deps             # Install Ansible collections
make box-list         # List available Vagrant boxes
make clean            # Clean build artifacts
make clean-all        # Clean everything including VMs
```

## Helper Scripts

### scripts/setup.sh

Setup development environment:

```bash
./scripts/setup.sh check    # Check prerequisites
./scripts/setup.sh deps     # Install dependencies
./scripts/setup.sh all      # Full setup
```

### scripts/verify.ps1

Run on Windows target to verify role applied correctly:

```powershell
# Verify all components
.\verify.ps1 -Component All

# Verify specific component
.\verify.ps1 -Component Choco
.\verify.ps1 -Component Security
.\verify.ps1 -Component Agents
.\verify.ps1 -Component CredSSP
```

## Project Structure

```
windows-base/
├── defaults/main.yml         # Default variables
├── tasks/
│   ├── main.yml              # Task orchestration
│   ├── choco.yml             # Chocolatey setup
│   ├── security.yml          # Security configuration
│   ├── agents.yml            # Agent installations
│   └── credssp.yml           # WSManCredSSP config
├── tests/
│   └── playbook.yml          # Test playbook
├── scripts/
│   ├── setup.sh              # Dev environment setup
│   └── verify.ps1            # Verification script
├── Makefile                  # Build automation
├── Vagrantfile               # Vagrant config
└── README.md
```

## Verification Commands

After running the role, verify configuration with these PowerShell commands:

```powershell
# Verify Chocolatey
choco -v

# Verify CredSSP
Get-WSManCredSSP

# Verify agents installed
Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -match "Splunk|Nessus|Seeker" }

# Verify services running
Get-Service | Where-Object { $_.Name -match "Splunk|Nessus|Seeker" }

# Verify security
Get-LocalGroupMember -Group "Administrators"
Get-Acl "D:\tomcat" | Format-List
Get-SmbShare
```

Or use the verification script:

```powershell
.\scripts\verify.ps1 -Component All
```

## Dependencies

Install required Ansible collections (installs to `./collections`):

```bash
# Use Make (recommended)
make deps

# Or manually
ansible-galaxy collection install ansible.windows chocolatey.chocolatey -p ./collections
```

## License

[MIT](LICENSE)
