# 🚑 SRE Incident Response Toolkit (Linux + Bash)

![Bash](https://img.shields.io/badge/Bash-Scripting-black?logo=gnu-bash)
![Linux](https://img.shields.io/badge/Linux-Ubuntu-E95420?logo=ubuntu)
![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20S3-orange?logo=amazon-aws)
![NGINX](https://img.shields.io/badge/NGINX-Web%20Server-green?logo=nginx)
![SRE](https://img.shields.io/badge/Role-SRE-blue)
![DevOps](https://img.shields.io/badge/Discipline-DevOps-purple)
![Automation](https://img.shields.io/badge/Focus-Automation-success)
![Logs](https://img.shields.io/badge/Domain-Log%20Management-informational)


Production-style **Cloud / DevOps / SRE portfolio project** that simulates real outages and demonstrates how to:

✅ Diagnose incidents fast  
✅ Fix root causes safely  
✅ Rotate & archive logs  
✅ Automate remediation  
✅ Generate audit reports  

Designed for Ubuntu EC2 + NGINX environments.

---

## 🔥 Scenario

Imagine it's **2AM and production is failing**:

• API returning 5xx errors  
• Disk almost full  
• Users complaining  

This toolkit helps you:

1️⃣ Diagnose fast (triage)  
2️⃣ Fix root cause (cleanup/rotation)  
3️⃣ Prevent repeat incidents (automation + archival)

---
# 🗂️ Repo Structure

```
sre-incident-toolkit/
│
├── scripts/
│   ├── triage.sh            # 📊 System + app health snapshot report
│   ├── logrotate-lite.sh    # 🧹 Rotate/compress/upload logs to S3
│
├── sample-data/
│   └── generate-logs.sh     # 🧪 Creates realistic production-style auth and access.logs for testing
|   └── generate-logs1.sh    # 🧪 Creates realistic production-style logs and archived .gz logs for testing
│
├── reports/                 # 📄 All generated reports 
├── screenshots/             # 🖼️ screenshots taken from production environment
│
├── README.md
└── .gitignore
```

---
# 🧰 Toolkit Components

## 🩺 triage.sh

Incident investigation script that gathers system + application signals into one report.

### Checks
- Last 20 application errors
- 5xx response counts
- Top failing endpoints
- Disk usage
- Memory usage
- CPU load
- System uptime
- Recommendation section

Run:

```bash
./triage.sh
```

### Output
reports/triage-report-YYYYMMDD-HHMMSS.csv

---

## ♻️ logrotate-lite.sh (UPDATED)

Lightweight **production-safe log cleanup + archival automation**.

### 🚀 Features
- Triggers when disk usage > 70%
- Removes DEBUG lines before rotation
- Rotates all *.log files
- Compresses rotated logs (.gz)
- Uploads archives to AWS S3
- Deletes:
  - *.log older than 7 days
  - *.gz / *.tar.gz older than 7 days
- Calculates space saved
- Prints summary
- Generates CSV audit report
- Cron friendly (Friday 10PM schedule)

Run:

```bash
./logrotate-lite.sh
```

### 📊 CSV Report
reports/logrotate-report-YYYYMMDD-HHMMSS.csv

Columns:
timestamp,disk_used_percent,files_rotated,files_uploaded,files_deleted,size_before,size_after,space_saved_mb,s3_path

Perfect for:
- audits
- metrics
- interview proof
- operational visibility

---

Cron example (Friday 10PM):

```
0 22 * * 5 /home/ubuntu/scripts/logrotate-lite.sh
```

---

## 🧪 generate-logs.sh — Realistic Test Data

Creates 2000+ line logs for realistic testing.

```bash
./generate-logs.sh
```

Generates:
- app.log
- access.log

---

## 🧪 generate-logs1.sh (NEW)

Realistic log generator for safe local testing.

### Generates
- 5 active service logs
- 15 additional .log files
- 15 rotated .gz archives
- 9 archives dated 20+ days old (for retention testing)
- INFO / DEBUG / ERROR logs
- 5xx responses
- failing endpoints

```bash
./generate-logs1.sh
```

### Purpose
Simulates production behavior so you can:
- test rotation logic
- simulate disk pressure
- validate deletion rules
- test retention safely
---

# 🎬 Quick Demo

```bash
# generate logs
./sample-data/generate-logs.sh
./sample-data/generate-logs1.sh

# copy to system paths
sudo mkdir -p /var/log/app /var/log/nginx /etc/app
sudo cp sample-data/*.log /var/log/app/
sudo cp sample-data/access.log /var/log/nginx/

# triage outage
./scripts/triage.sh

# cleanup disk + archive
./scripts/logrotate-lite.sh
```
---
# 🧠 Skills Demonstrated

- Bash scripting
- Linux CLI troubleshooting
- grep / awk / sed pipelines
- systemctl & services
- cron scheduling
- gzip compression
- AWS CLI + S3
- Log lifecycle management
- Incident response mindset

---
# 👤 Author

Built as a practical DevOps/SRE portfolio project to demonstrate real-world operational skills.

Happy debugging 🚀
