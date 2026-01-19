# Windows Base

Ansible role for setting up a Windows base configuration with Chocolatey package manager installed to a custom directory.

## Requirements

- Ansible 2.14+
- `ansible.windows` collection
- `chocolatey.chocolatey` collection
- Target: Windows host accessible over WinRM with administrator rights

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `choco_install_dir` | `C:/choco` | Chocolatey installation directory |
| `choco_tools_dir` | `C:/choco-tools` | Chocolatey tools directory for portable apps |
| `choco_install_ps1` | `C:/Windows/Temp/choco-install.ps1` | Temporary path for install script |

## Features

- Configures custom Chocolatey installation directory (avoids default `C:\ProgramData\chocolatey`)
- Sets `ChocolateyInstall` and `ChocolateyToolsLocation` environment variables (machine scope)
- Downloads and installs Chocolatey from official source
- Adds Chocolatey bin directory to system PATH
- Validates installation with version check

## Example Playbook

```yaml
---
- hosts: windows_servers
  roles:
    - role: windows-base
      vars:
        choco_install_dir: "D:/choco"
        choco_tools_dir: "D:/choco-tools"
```

## Dependencies

Install required Ansible collections:

```bash
ansible-galaxy collection install ansible.windows chocolatey.chocolatey
```

## License

[MIT](LICENSE)
