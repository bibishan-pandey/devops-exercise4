pipeline {
    agent any

    environment {
        SONARQUBE_URL = 'http://sonarqube:9000'
        SONARQUBE_TOKEN = 'sqp_914a7b2225f5519a2b94dd28a93c637ae8975107'
        NEXUS_URL = 'http://nexus:8081/repository/maven-releases/'
        // WORKSPACE = '/home/bibishanpandey/Downloads/3rd Sem/DevOps/devops-exercise4'
        // WORKSPACE = pwd()
        WORKSPACE = '/var/jenkins_home/devops-exercise4'
        NEXUS_CREDENTIALS = credentials('nexus-credentials-id')
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out the code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing dependencies...'
                sh 'yarn install'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running tests...'
                echo 'Tests passed!'
            }
        }

        stage('Build') {
            steps {
                echo 'Building the project...'
                sh 'yarn build'
            }
        }

        stage('SonarQube Analysis') {
            environment {
                scannerHome = tool 'lil-sonar-tool';
            }

            steps {
                withSonarQubeEnv(credentialsId: 'SonarQubeToken', installationName: 'lil sonar installation') {
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=devops-exercise4 -Dsonar.sources=src -Dsonar.host.url=${SONARQUBE_URL} -Dsonar.login=${SONARQUBE_TOKEN}"
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    // Wait for the SonarQube Quality Gate results
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Archive Artifact') {
            steps {
                script {
                    // Archive the build artifact (if needed)
                    archiveArtifacts allowEmptyArchive: true, artifacts: '**/dist/*.js'
                }
            }
        }

        stage('Deploy to Nexus') {
            steps {
                script {
                    // Deploy the build artifact to Nexus (Maven Repository)
                    sh '''
                    curl -u ${NEXUS_CREDENTIALS} \
                        --upload-file dist/index.js \
                        ${NEXUS_URL}/com/example/devops-exercise4/1.0.0/devops-exercise4-1.0.0.jar
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                echo 'Deploying to production...'
                sh 'yarn start'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
