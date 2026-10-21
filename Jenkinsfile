pipeline {
    agent any

    environment {
        IMAGE_NAME     = 'visionassist'
        IMAGE_TAG      = "jenkins-${BUILD_NUMBER}"
        CONTAINER_NAME = 'visionassist-jenkins'
        HOST_PORT      = '8082'
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Unit test') {
            steps {
                sh '''
                    node --version
                    rc=0
                    node --test > unit-test-report.txt 2>&1 || rc=$?
                    cat unit-test-report.txt
                    exit $rc
                '''
            }
        }

        stage('SonarQube scan') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'
                    withSonarQubeEnv('sonarqube') {
                        sh "${scannerHome}/bin/sonar-scanner"
                    }
                }
            }
        }

        stage('Docker build') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Trivy image scan') {
            steps {
                sh '''
                    rc=0
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy:latest image --quiet \
                      --severity HIGH,CRITICAL --exit-code 1 --format table \
                      ${IMAGE_NAME}:${IMAGE_TAG} > trivy-image-report.txt 2>&1 || rc=$?
                    cat trivy-image-report.txt
                    exit $rc
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker rm -f ${CONTAINER_NAME} || true
                    docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:8080 ${IMAGE_NAME}:${IMAGE_TAG}
                    for i in 1 2 3 4 5 6 7 8 9 10; do
                      if curl -fsS http://host.docker.internal:${HOST_PORT} > /dev/null; then
                        echo "Site is up on host port ${HOST_PORT}"
                        exit 0
                      fi
                      sleep 3
                    done
                    echo "Site did not respond in time"
                    exit 1
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '*-report.txt', allowEmptyArchive: true
        }
    }
}
