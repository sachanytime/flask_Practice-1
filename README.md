# Student Registration System

A simple **Flask** web application to manage student records with **MongoDB** as the backend database. Users can **add, view, update, and delete** student details.

---

## Features

* List all students on the home page
* Add a new student
* Update existing student details
* Delete a student with confirmation
* Simple and responsive UI using Bootstrap

---

## Tech Stack

* **Backend:** Python, Flask
* **Database:** MongoDB (via Flask-PyMongo)
* **Frontend:** HTML, Jinja2 templates, Bootstrap 5
* **Environment Variables:** Managed via `.env` file

---

## Setup Instructions

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd <repo-folder>
```

### 2. Create and activate a virtual environment

```bash
python -m venv venv
# Activate venv
# Windows:
venv\Scripts\activate
# Linux / Mac:
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

**`requirements.txt` example:**

```
Flask
Flask-PyMongo
python-dotenv
bson
```

### 4. Configure environment variables

Create a `.env` file in the project root:

```
MONGO_URI=<your-mongodb-connection-string>
SECRET_KEY=<your-secret-key>
```

### 5. Run the application

```bash
python app.py
```

Open your browser at: [http://localhost:8000](http://localhost:8000)

---

## Project Structure

```
project/
│
├── templates/
│   ├── base.html
│   ├── index.html
│   ├── add_student.html
│   ├── update_student.html
│
├── app.py
├── requirements.txt
└── .env
```

---

## Screenshots

**Home Page**
Lists all students with Edit/Delete buttons.
- <img width="1902" height="607" alt="image" src="https://github.com/user-attachments/assets/a58a6a6d-4978-4769-8074-232e4d31e69d" />


**Add Student**
Form to add a new student.
- <img width="1897" height="801" alt="image" src="https://github.com/user-attachments/assets/d65d25c3-ebb5-410a-adb1-e130ad7c5878" />


**Update Student**
Form pre-filled with student details.
- <img width="1905" height="897" alt="image" src="https://github.com/user-attachments/assets/04febf01-879f-431f-ab07-abcfb993acf1" />



---

## Notes

* Make sure MongoDB is running and accessible via the URI in `.env`
* Delete action includes a confirmation page to prevent accidental deletion
* Uses `ObjectId` from `bson` to work with MongoDB document IDs
* If you use MongoDB Atlas on macOS, install dependencies again (`pip install -r requirements.txt`). This project now uses `certifi` CA bundle explicitly to avoid common TLS certificate verification failures with `pymongo`.

---

## License

MIT License

---





---

# CI/CD Pipelines — Detailed Setup

This repository ships **two** CI/CD pipelines for the Flask student-management app:

- **Jenkins** — `Jenkinsfile` (Build → Test → Deploy-to-Staging, email notifications)
- **GitHub Actions** — `.github/workflows/ci-cd.yml` (Install → Test → Build → Deploy-Staging → Deploy-Production)

The app is Flask + MongoDB (`flask_pymongo`) on port 5000; tests use Flask's test client against a
MongoDB test database.

## Prerequisites
| Component | Requirement |
|-----------|-------------|
| Python | 3.11 with `pip` and `venv` |
| MongoDB | reachable via `MONGO_URI` (local container, Atlas, or CI service) |
| Jenkins | Git, Pipeline, Blue Ocean, JUnit, Email-ext, GitHub Integration plugins |
| GitHub | repo with `main` **and** `staging` branches; Actions enabled |

---

## Part 1 — Jenkins pipeline

### Step 1 — Install Jenkins + Python (on an EC2/VM)
```bash
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk python3 python3-venv python3-pip
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt-get update && sudo apt-get install -y jenkins
sudo systemctl enable --now jenkins        # http://<host>:8080
```
Unlock Jenkins (`/var/lib/jenkins/secrets/initialAdminPassword`) and install the plugins listed above.

### Step 2 — Configure credentials
*Manage Jenkins → Credentials → System → Global* — add **Secret text** entries:
- `flask-mongo-uri` — the MongoDB URI
- `flask-secret-key` — the Flask `SECRET_KEY`

### Step 3 — Create the pipeline job
*New Item → Pipeline* → **Pipeline script from SCM** → Git → your fork URL → branch `*/main` →
Script Path `Jenkinsfile`.

### Step 4 — Trigger on push to main
- In the job: enable **GitHub hook trigger for GITScm polling**.
- In GitHub: *Settings → Webhooks → Add webhook* → Payload URL `http://<jenkins>:8080/github-webhook/`,
  content type `application/json`, event **push**.

### Step 5 — Email notifications
*Manage Jenkins → System → Extended E-mail Notification* → SMTP server/port/credentials. The
`post { success / failure }` blocks in the `Jenkinsfile` email `sdt11_a@blog4bharat.com` on each outcome.

### Pipeline stages (Jenkinsfile)
| Stage | Command |
|-------|---------|
| Checkout | `checkout scm` |
| Build | `python3 -m venv .venv && pip install -r requirements.txt` |
| Test | `pytest -v --junitxml=reports/junit.xml` (recorded via JUnit) |
| Deploy to Staging | on `main`: `bash deploy/deploy_staging.sh` |

---

## Part 2 — GitHub Actions workflow

### Step 1 — Branches
Ensure both branches exist:
```bash
git checkout -b staging && git push -u origin staging
```

### Step 2 — Configure secrets
*Settings → Secrets and variables → Actions* — add:
| Secret | Used by | Purpose |
|--------|---------|---------|
| `MONGO_URI` | deploy-staging | staging DB URI |
| `STAGING_SSH_KEY`, `STAGING_HOST` | deploy-staging | SSH to staging |
| `PROD_SSH_KEY`, `PROD_HOST`, `PROD_MONGO_URI` | deploy-production | production deploy |

### Step 3 — Workflow jobs (`.github/workflows/ci-cd.yml`)
| Job | Trigger | Action |
|-----|---------|--------|
| **test** | push/PR to main or staging | starts a `mongo:6` service, `pip install`, `pytest`, uploads JUnit |
| **build** | after test passes | packages the app into a tarball artifact |
| **deploy-staging** | push to `staging` | SSH-deploys to the staging host |
| **deploy-production** | a **release is published** (tag) | SSH-deploys the tagged release to production |

### Step 4 — Deploy to production
Create a release/tag to trigger the production job:
```bash
git tag v1.0.0 && git push origin v1.0.0
# then publish a Release for v1.0.0 in the GitHub UI
```

---

## Running tests locally
```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
export MONGO_URI="mongodb://localhost:27017/test_student_db" SECRET_KEY="dev"
pytest -v          # 4 passed
```

## Security note
The upstream `start_flask.sh` contains a **hard-coded MongoDB Atlas credential** — remove it and
**rotate the password**. Both pipelines read the URI from a Jenkins credential / GitHub secret; no
real credentials are committed.

## Screenshots
See `screenshots/` — the full chain: fork/clone, Jenkins install + plugins + credentials + job
config + webhook + email config, the Blue Ocean pipeline, console, JUnit results, success/failure
emails, the deployed staging app, the branches, the GitHub Actions run list + run detail + test job
+ production deploy + secrets.
