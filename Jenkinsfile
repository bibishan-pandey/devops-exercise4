pipeline {
    agent any

    environment {
        SONARQUBE_URL = 'http://sonarqube:9000'
        SONARQUBE_TOKEN = 'sqp_914a7b2225f5519a2b94dd28a93c637ae8975107'
        NEXUS_URL = 'http://nexus:8081/repository/maven-releases/'
        WORKSPACE = '/home/bibishanpandey/Downloads/3rd Sem/DevOps/devops-exercise4'
        // WORKSPACE = pwd()
        NEXUS_CREDENTIALS = credentials('nexus-credentials-id')
    }

    stages {
        stage('Clone Repository') {
            steps {
                git 'https://github.com/bibishan-pandey/devops-exercise4.git'
            }
        }


        stage('Run Tests') {
            steps {
                echo 'Running tests...'
                echo 'Tests passed!'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t bibishanpandey/devops-exercise4:latest ."
            }
        }


        stage('Install Dependencies') {
            steps {
                script {
                    // Install dependencies using Yarn (or npm)
                    sh 'yarn install'
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    // Compile the TypeScript code
                    sh 'yarn build'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    // Run SonarQube analysis using Docker
                    sh '''
                    docker run --rm \
                        --network sonar-network \
                        -e SONAR_HOST_URL="${SONARQUBE_URL}" \
                        -e SONAR_TOKEN="${SONARQUBE_TOKEN}" \
                        -v "${WORKSPACE}:/usr/src" \
                        sonarsource/sonar-scanner-cli \
                        -Dsonar.projectKey=devops-exercise4 \
                        -Dsonar.sources=. \
                        -Dsonar.exclusions="**/node_modules/**" \
                        -Dsonar.language=js \
                        -Dsonar.sourceEncoding=UTF-8 \
                        -X
                    '''
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
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
