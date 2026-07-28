![CI/CDefense](cicdefense-updated.png)

# CI/CDefense

**Practice software supply chain security with CI/CDefense!**

‼️ *NOTE: THIS IS STILL IN ACTIVE DEVELOPMENT!!!*

Build your own Terraform lab for CI/CD pipeline and software supply chain security testing.

## Lab Architecture

Three VMs on a private network, reachable only through a managed jump host. No VM has a public IP.

- **Ubuntu (latest LTS)** — primary CI runner, equivalent to a self-hosted GitLab Runner or GitHub Actions runner
- **Windows Server 2022 Datacenter** — secondary runner for Windows binaries and .NET builds
- **notkali** — Ubuntu-based adversary and DAST node, loaded with offensive tooling for simulating supply chain attacks and scanning for exposed secrets

Network posture:

- VMs can reach each other
- VMs can reach the internet (egress allowed for package and model pulls)
- Nothing on the internet can reach the VMs
- Operator access is via Azure Bastion

## What Gets Built

Azure (17 resources):

- Resource group, virtual network, workload subnet, AzureBastionSubnet
- Network security group with least-privilege rules, plus subnet association
- Azure Bastion host and its static public IP
- 3 network interfaces, no public IPs
- 3 virtual machines (all Ubuntu 24.04 except the Windows runner)
- 3 VM extensions that install desktops and tooling

## Prerequisites

- Terraform CLI 1.9 or newer
- Azure CLI
- An Azure subscription with billing enabled
- Git

Optional but recommended: VS Code with the HashiCorp Terraform extension.

## Quick Start

### 1. Authenticate

```powershell
az login
az account show --query id --output tsv
```

Copy the subscription GUID that prints.

### 2. Create your variables file

`terraform.tfvars` is gitignored and is not in this repo. Create it from the template:

```powershell
copy terraform.tfvars.example terraform.tfvars
```

Then fill in:

- `subscription_id` — the GUID from step 1
- `location` — defaults to `centralus`
- `admin_username` — cannot be admin, administrator, root, guest, user, or test
- `admin_password` — 12+ characters, mixed case, number, symbol

To keep the password off disk, set it as an environment variable instead and omit it from the file:

```powershell
$env:TF_VAR_admin_password = "your-password-here"
```

### 3. Deploy

```powershell
terraform init
terraform validate
terraform plan
terraform apply
```

Expect 20 to 40 minutes. Bastion takes 5 to 10 minutes on its own, and the notkali extension installs a substantial offensive toolset.

### 4. Connect

```powershell
terraform output
```

In the Azure Portal, go to the resource group, select a VM, then Connect, then Bastion. Sign in with your admin username and password.

All three VMs accept RDP. xrdp is installed on the Linux nodes so they present a graphical desktop rather than a bare shell.

### 5. Tear down

```powershell
terraform destroy
```

Do this at the end of every session.

## Installed Tooling

Provisioning scripts live in `scripts/` and run automatically via VM extensions.

All nodes:

- git
- VS Code
- Ollama

Windows Server 2022 (installed via direct download, no package manager):

- git
- VS Code
- Ollama
- IE Enhanced Security Configuration disabled

Ubuntu (CI runner):

- XFCE desktop and xrdp

notkali (adversary / DAST node):

- XFCE desktop and xrdp
- Recon and OSINT: nmap, masscan, dnsrecon, amass, whatweb, theHarvester
- Web app testing: sqlmap, nikto, gobuster, ffuf, wfuzz, OWASP ZAP
- Secrets scanning: trufflehog, gitleaks
- Traffic: Wireshark, mitmproxy
- Burp Suite Community is downloaded to the Downloads folder but not installed; install it yourself if you want it

### Language models

Ollama is installed but models are not pulled during provisioning, since the downloads are large enough to risk timing out the extension. Pull them after first login:

```bash
ollama pull gemma4:e4b
ollama pull R4C3R/minicpm5-1b-fable5-heretic
```

The default `Standard_D2s_v5` size (2 vCPU, 8 GB RAM) runs small models comfortably. Bump `vm_size` in `terraform.tfvars` for more headroom.

## Cost

This lab bills by the hour. Destroy it when you are not using it for your sanity.

Roughly 0.55 to 0.65 USD per hour in centralus, broken down as:

- 3 D2s_v5 VMs, about $0.29 each region-dependent
- Azure Bastion Basic SKU, about $0.19
- OS disks (64 GB StandardSSD on the Linux nodes), a few cents per hour
- Static public IP, about $0.005

Free: resource group, virtual network, subnets, and network security group

Verify against the Azure pricing calculator for your region and subscription.

Notes:

- Bastion bills simply for existing, whether or not you are connected through it
- OS disks bill even while a VM is stopped; stopping is not the same as destroying
- `terraform destroy` removes everything, including disks

A four-hour session costs a few dollars. A forgotten week costs around $100 USD.

## Security Notes

Please keep in mind that this is a lab. I deliberately chose convenience over hardening for several things:

- Password authentication is enabled on the Linux VMs. SSH keys are the commonly accepted security practice. This is defensible only because the VMs have no public IP and are reachable solely through Bastion. To switch, replace `disable_password_authentication = false` with an `admin_ssh_key` block.
- Terraform state contains secrets in plaintext. Marking a variable sensitive only redacts it from console output. State files are gitignored, but a production setup would use a remote backend with encryption at rest and state locking.
- Provisioning scripts use curl piped to shell. The Ollama installer executes a remote script unreviewed. This is the standard install path and TBH, a live example of the type of thing this lab is meant to study, among other configurations in this section.
- Several offensive tools on notkali are installed from vendor install scripts and GitHub release binaries rather than signed distro packages. This is convenient and common, and it is also exactly the kind of unverified-supply-chain step this lab exists to study.
- Image versions are set to `latest` rather than pinned. This is done only for convenience. The end result is that the same configuration produces different images over time. If you want completely reproducible builds, pin the exact version you want.
- Egress is unrestricted. Adding outbound deny rules to the NSG is the natural next hardening exercise, and it is the control that would stop a compromised runner from exfiltrating secrets.

Never commit `terraform.tfvars` or `.tfstate` files. Both are gitignored at the repo root.

## Troubleshooting

**terraform plan prompts for a variable.** A required variable has no value. Check that `terraform.tfvars` exists and is filled in.

**Subscription ID is not known by Azure CLI.** The GUID in `terraform.tfvars` does not match your logged-in session. Run `az account list --all --output table` and compare. Also confirm you are logged into the correct account, especially if you use more than one.

**SkuNotAvailable or NotAvailableForSubscription.** Your regional vCPU quota is likely zero or too low, or the VM size family is not offered to your subscription in that region. Check with `az vm list-usage --location <region> --output table` and look at the Limit column. Fix by requesting a quota increase (Portal, search Quotas, Compute) or by choosing a region or size that is available to your subscription.

**Marketplace offer removed for new purchase.** The image was withdrawn from the Marketplace (this is why the adversary node is stock Ubuntu plus tooling rather than the official Kali image). Use a stock image and install tooling via the provisioning script instead.

**PlatformImageNotFound.** A marketplace image reference has drifted. Verify with:

```powershell
az vm image list --publisher <publisher> --offer <offer> --location centralus --all --output table
```

**Extension fails with "VM has reported a failure".** Terraform cannot see inside the script. Connect via Bastion and read the logs. On Linux, `/var/log/azure/custom-script/handler.log`. On Windows, read stderr under `C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\*\Downloads\`.

**Blank grey screen after RDP to a Linux VM.** The `.xsession` file is missing or has the wrong owner. Check that the setup script wrote it for the correct user.

**Nothing else works.** Turn on debug logging:

```powershell
$env:TF_LOG = "DEBUG"
terraform plan
$env:TF_LOG = ""
```

## Roadmap

- [ ] Detection and logging layer (in progress): Sysmon on Windows, auditd and osquery on the runners, SBOM and vuln scanning with Syft, Grype, and Trivy
- [ ] Remote state backend with locking
- [ ] Egress filtering exercise
- [ ] Pinned image versions for reproducible builds
- [ ] Seeded vulnerable pipeline for attack scenarios

## License

MIT.