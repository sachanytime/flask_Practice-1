pipeline {
  agent any

  environment {
    // MongoDB URI and app secret come from Jenkins credentials — never hard-coded.
    MONGO_URI  = credentials('flask-mongo-uri')
    SECRET_KEY = credentials('flask-secret-key')
    VENV       = ".venv"
  }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  triggers {
    // Build on every push to main (GitHub webhook -> "GitHub hook trigger for GITScm polling")
    githubPush()
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build') {
      steps {
        sh '''
          python3 -m venv $VENV
          . $VENV/bin/activate
          pip install --upgrade pip
          pip install -r requirements.txt
        '''
      }
    }

    stage('Test') {
      steps {
        sh '''
          . $VENV/bin/activate
          # A MongoDB instance must be reachable via $MONGO_URI (local mongo or a service container).
          pytest -v --junitxml=reports/junit.xml
        '''
      }
      post {
        always { junit allowEmptyResults: true, testResults: 'reports/junit.xml' }
      }
    }

    stage('Deploy to Staging') {
      when { branch 'main' }
      steps {
        sh '''
          . $VENV/bin/activate
          echo "Deploying to staging environment..."
          # Package and restart the staging app (systemd service on the staging host)
          bash deploy/deploy_staging.sh
        '''
      }
    }
  }

  post {
    success {
      mail to: 'sdt11_a@blog4bharat.com',
           subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
           body: "Build, tests and staging deploy succeeded.\n${env.BUILD_URL}"
    }
    failure {
      mail to: 'sdt11_a@blog4bharat.com',
           subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
           body: "The pipeline failed at stage ${env.STAGE_NAME}.\nConsole: ${env.BUILD_URL}console"
    }
  }
}
