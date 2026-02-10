# 🚑⚙️ Linux SRE Incident Response & Automation Toolkit

> **Hands‑on DevOps/SRE portfolio project that simulates real production outages and demonstrates diagnosing, remediating, and preventing issues using Bash + Linux + AWS.**

Built to showcase:
- 🐧 Linux troubleshooting
- 📊 Log analysis (grep / awk / sed / sort)
- 🧠 Incident response workflows
- 🧹 Log rotation & cleanup
- ☁️ S3 archival
- ⏰ Cron automation
- 🚀 EC2 bootstrapping

---

# ✨ Project Story

Imagine it's **2AM** and production is failing:

- API returning 5xx errors  
- Disk almost full  
- Users complaining  

This toolkit helps you:

1️⃣ Diagnose fast (triage)  
2️⃣ Fix root cause (cleanup/rotation)  
3️⃣ Prevent repeat incidents (automation + archival)

Exactly what real **SRE/DevOps engineers** do daily.

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
│   └── generate-logs.sh     # 🧪 Creates 2000+ line realistic logs
│
├── reports/                 # 📄 Generated reports (gitignored)
├── screenshots/             # 🖼️ Demo screenshots
│
├── README.md
└── .gitignore
```

---

# 🧰 Scripts Overview

## 📊 triage.sh — Incident Snapshot

Collects everything you'd check during an outage.

✅ Last 20 app errors  
✅ Count 5xx responses  
✅ Top failing endpoints  
✅ Disk usage  
✅ Memory usage  
✅ CPU load  
✅ System uptime  
✅ Recommendations section  
✅ Saves timestamped report  

Run:

```bash
./triage.sh
```

Output:

```
triage-report-YYYYMMDD-HHMMSS.csv
```

---

## 🧹 logrotate-lite.sh — Prevent Disk Outages

Triggers only when disk > 70%.

Automatically:

✅ Removes DEBUG lines  
✅ Rotates logs  
✅ Compresses (gzip)  
✅ Uploads to S3  
✅ Deletes logs > 7 days  
✅ Calculates space saved  
✅ Prints summary  

Run:

```bash
./logrotate-lite.sh
```

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

# 🎬 Quick Demo

```bash
# generate logs
./sample-data/generate-logs.sh

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

# 📈 Example Output

```
Total 5xx responses: 213
Top failing endpoint: /api/login
Disk usage before: 1.4G
Disk usage after: 650M
Space saved: 750 MB
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
