# Intune Management Extension Health Verifier

> Verifies the Intune Management Extension (IME) service installation, health status, and triggers a device sync to confirm end-to-end IME readiness on a Windows device.

## Overview

This PowerShell script was extracted from an article on [MSEndpoint.com](https://msendpoint.com) and is part of the professional automation portfolio.

### Quick Start

```powershell
# Clone the repository
git clone https://github.com/Msendpoint/intune-ime-health-check.git
cd intune-ime-health-check

# One-click install & run (checks prerequisites, installs modules, launches script)
.\Install.ps1

# Or run the script directly
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\intune-ime-health-check.ps1
```

## Script Usage

```powershell
.\scripts\intune-ime-health-check.ps1
```

## Tech Stack

PowerShell, Microsoft Intune, Windows Registry, Windows Services, Task Scheduler

## Requirements

- PowerShell 7.0 or later
- Microsoft Graph CLI (if applicable)
- Exchange Online Management module (if applicable)
- Appropriate administrative permissions

## About the Author

**Souhaiel Morhag** — Microsoft 365 & Intune Automation Specialist

- 🌐 **Blog**: [https://msendpoint.com](https://msendpoint.com) — Enterprise endpoint management insights
- 📚 **Academy**: [MSEndpoint Academy](https://app.msendpoint.com/academy) — Professional training & certifications
- 💼 **LinkedIn**: [Souhaiel Morhag](https://linkedin.com/in/souhaiel-morhag) — Connect for collaboration
- 🐙 **GitHub**: [@Msendpoint](https://github.com/Msendpoint)

## Source Article

This script originated from:
**[Intune Management Extension: Complete Setup Guide](https://msendpoint.com/article/intune-management-extension-complete-setup-guide)**

Published on MSEndpoint.com — Enterprise endpoint management blog

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -m 'feat: add improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

## License

MIT License — see [LICENSE](LICENSE) for details.

## Support

- Report issues: [GitHub Issues](https://github.com/Msendpoint/intune-ime-health-check/issues)
- Questions: Comment on the original article or reach out on LinkedIn

---

*Developed with ❤️ by [MSEndpoint.com](https://msendpoint.com) — Your Microsoft 365 Endpoint Management Partner*