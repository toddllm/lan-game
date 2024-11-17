#!/bin/bash
# scripts/setup-jenkins.sh
set -e

# Create jenkins directory in project root
mkdir -p jenkins-pipelines

# Create LAN pipeline
cat > jenkins-pipelines/Jenkinsfile.lan << 'EOL'
pipeline {
    agent any

    environment {
        GAME_SERVER_URL = 'http://192.168.68.141:5001'
        GAME_PASSWORD = credentials('shape-game-password')
        NODE_VERSION = '18'
    }

    options {
        // Keep build logs for 10 days
        buildDiscarder(logRotator(daysToKeepStr: '10'))
        // Timeout if build takes more than 30 minutes
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Setup') {
            steps {
                // Clean workspace
                cleanWs()
                
                // Checkout code
                checkout scm
                
                // Setup Node.js
                sh '''
                    # Install Node.js if not present
                    if ! command -v node &> /dev/null; then
                        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
                        apt-get install -y nodejs
                    fi
                    
                    # Install dependencies
                    npm install
                    npx playwright install chromium --with-deps
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    # Run tests
                    GAME_SERVER_URL=${GAME_SERVER_URL} npm test
                '''
            }
            post {
                always {
                    // Archive test results
                    archiveArtifacts artifacts: 'test-results/**/*', allowEmptyArchive: true
                    archiveArtifacts artifacts: 'playwright-report/**/*', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        failure {
            echo 'Tests failed! Check the test results for details.'
        }
        success {
            echo 'All tests passed successfully!'
        }
        always {
            // Clean up
            cleanWs()
        }
    }
}
EOL

# Create Public pipeline
cat > jenkins-pipelines/Jenkinsfile.public << 'EOL'
pipeline {
    agent any

    environment {
        GAME_SERVER_URL = 'http://24.29.85.43:5001'
        GAME_PASSWORD = credentials('shape-game-password')
        NODE_VERSION = '18'
    }

    options {
        buildDiscarder(logRotator(daysToKeepStr: '10'))
        timeout(time: 45, unit: 'MINUTES')  // Longer timeout for public tests
    }

    stages {
        stage('Setup') {
            steps {
                cleanWs()
                checkout scm
                
                sh '''
                    if ! command -v node &> /dev/null; then
                        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
                        apt-get install -y nodejs
                    fi
                    
                    npm install
                    npx playwright install chromium --with-deps
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    # Run tests with retries for public network
                    GAME_SERVER_URL=${GAME_SERVER_URL} npm test -- --retries=2
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'test-results/**/*', allowEmptyArchive: true
                    archiveArtifacts artifacts: 'playwright-report/**/*', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        failure {
            echo 'Tests failed! Check the test results for details.'
        }
        success {
            echo 'All tests passed successfully!'
        }
        always {
            cleanWs()
        }
    }
}
EOL

echo "Jenkins pipeline files created in jenkins-pipelines directory"
echo "Once Jenkins is up, create two pipeline jobs using these files"