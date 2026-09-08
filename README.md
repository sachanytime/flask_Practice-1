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

# CI/CD Pipelines

This repository ships **two** CI/CD pipelines for the Flask student-management app: a **Jenkins**
pipeline (`Jenkinsfile`) and a **GitHub Actions** workflow (`.github/workflows/ci-cd.yml`). Both
install dependencies, run the pytest suite, and deploy to staging; GitHub Actions also deploys to
production on a tagged release.

## Prerequisites
- Python 3.11, `pip`
- A reachable **MongoDB** for the tests (`MONGO_URI`). Locally: `mongodb://localhost:27017/...`
- Jenkins with the Git, Pipeline, JUnit and Email Extension plugins (for the Jenkins path)

## 1) Jenkins pipeline (`Jenkinsfile`)
Stages: **Checkout → Build (pip install in a venv) → Test (pytest, JUnit report) → Deploy to
Staging** (on `main`).

**Setup**
1. Install Jenkins (VM or cloud) and the plugins above; ensure Python 3 is on the agent.
2. Add credentials in Jenkins: `flask-mongo-uri` and `flask-secret-key` (Secret text).
3. Create a *Multibranch* or *Pipeline* job pointing at your fork; Jenkins reads the `Jenkinsfile`.
4. **Trigger:** enable *GitHub hook trigger for GITScm polling* and add a webhook
   (`http://<jenkins>/github-webhook/`) so pushes to `main` start a build.
5. **Email notifications:** configure *Manage Jenkins → System → Extended E-mail Notification*
   (SMTP). The `post { success / failure }` blocks email `sdt11_a@blog4bharat.com` on each outcome.

Tests need MongoDB; run a local `mongo` container on the agent or point `flask-mongo-uri` at one.

## 2) GitHub Actions workflow (`.github/workflows/ci-cd.yml`)
Jobs: **test → build → deploy-staging → deploy-production**.
- **test** — spins up a `mongo:6` **service container**, installs deps, runs `pytest`, uploads the
  JUnit report.
- **build** — packages the app into a tarball artifact (only if tests pass).
- **deploy-staging** — runs when you push to the **`staging`** branch.
- **deploy-production** — runs when a **release is published** (tagged).

**Branches:** keep both a `main` and a `staging` branch.

**Required GitHub Secrets** (Settings → Secrets and variables → Actions):
| Secret | Used by | Purpose |
|--------|---------|---------|
| `MONGO_URI` | staging | app database URI for staging |
| `STAGING_SSH_KEY`, `STAGING_HOST` | deploy-staging | SSH to the staging host |
| `PROD_SSH_KEY`, `PROD_HOST`, `PROD_MONGO_URI` | deploy-production | production deploy |

> **Security note:** never commit real credentials. Move any hard-coded connection string (e.g. in
> `start_flask.sh`) into a secret and rotate it. The workflow reads everything from GitHub Secrets.

## Running tests locally
```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
export MONGO_URI="mongodb://localhost:27017/test_student_db" SECRET_KEY="dev"
pytest -v
```
