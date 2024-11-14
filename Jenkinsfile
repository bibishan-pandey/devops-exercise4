pipeline {
    agent any

    tools {
        nodejs 'NodeJS 18.20.5'
    }

    environment {
        SCANNER_HOME = tool 'SonarQube Scanner 6.2.1.4610'

        NODEJS_HOME = tool name: 'NodeJS 18.20.5'
        PATH = "${NODEJS_HOME}/bin:${env.PATH}"

        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_CREDENTIALS_ID = 'NexusNPMCredentials'
        NEXUS_AUTH_CREDENTIALS_ID = 'NexusAuthCredentials'

        SONAR_HOST_URL = "http://172.17.0.1:9000"
    }


    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                withCredentials([file(credentialsId: 'NexusNPMCredentials', variable: 'npmrc')]) {
                    echo 'Building...'
                    sh "npm install --userconfig $npmrc --registry http://172.17.0.1:8081/repository/devops-exercise4-proxy/ --loglevel verbose"
                }
            }
        }

        stage('Build') {
            steps {
                withCredentials([file(credentialsId: 'NexusNPMCredentials', variable: 'npmrc')]) {
                    echo 'Building...'
                    sh "npm run build --userconfig $npmrc --registry http://172.17.0.1:8081/repository/devops-exercise4-proxy/ --loglevel verbose"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv() {
                        sh """${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=http://172.17.0.1:9000 \
                        -Dsonar.token=sqp_b7fdcdf36cbd945c440fd56ace7e31d701761ae0 \
                        -Dsonar.exclusions=**/node_modules/** \
                        -Dsonar.projectKey=DevOps-Exercise-4"""
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    sh '''#!/bin/bash
                    curl http://172.17.0.1:9000/api/server/version
                    '''


                    sleep(time: 30, unit: 'SECONDS')
                    def qualityGate = waitForQualityGate()
                    if (qualityGate.status == 'IN_PROGRESS') {
                        sleep(time: 30, unit: 'SECONDS')
                        error "Quality Gate is in progress. Trying again..."
                    }

                    if (qualityGate.status != 'OK') {
                        error "Quality Gate failed: ${qualityGate.status}"
                    }
                    else {
                        echo "Quality Gate passed: ${qualityGate.status}"
                    }
                }
            }
        }


        stage('Publish to Nexus') {
            steps {
                withCredentials([file(credentialsId: 'NexusNPMCredentials', variable: 'npmrc')]) {
                    echo 'Publishing to Nexus...'
                    sh "npm publish --userconfig ${npmrc} --loglevel verbose"
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
