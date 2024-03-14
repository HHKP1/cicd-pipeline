// Multibranch Pipeline
pipeline {
    agent any

    tools { nodejs "node" }
    stages {
        stage('Checkout SCM...') {
            steps {
                // Checkout the multibranch Git repository
                script {
                    checkout([$class: 'GitSCM', branch: [name: 'main'], userRemoteConfigs: [[url: 'https://github.com/HHKP1/cicd-pipeline.git']]])
                    sh "echo ${env.BRANCH_NAME}"
                }
            }
        }
        stage ("lint Dockerfile...") {
            agent {
                docker {
                    image 'hadolint/hadolint:latest-debian'
                    reuseNode true
                }
            }
            steps {
                sh 'hadolint Dockerfile | tee hadolint_lint.txt'
            }
        }
        stage('Build...') {
            steps {
                sh "ls -la && pwd"
                sh 'npm config ls'
                sh 'npm install'
            }
        }
        stage('Test...') {
            steps {
                sh 'npm config ls'
                sh 'npm test'
            }
        }
        stage('Docker build...') {
            steps {
                // Login to Docker Hub using access token
                withCredentials([string(credentialsId: 'docker-access-token', variable: 'DOCKER_ACCESS_TOKEN')]) {
                    sh "echo ${DOCKER_ACCESS_TOKEN} | docker login --username hhkp --password-stdin"
                    sh "docker build -t hhkp/node${params.BRANCH}:${params.imageTag} ."
                    sh "docker push hhkp/node${params.BRANCH}:${params.imageTag}"
                }
            }
        }
        stage('Deploy...') {
            steps {
                script {
                    def dockerImage = "nodemain:${params.imageTag}"
                    def containerName = "main_container"
                    
                    if (params.BRANCH == 'dev') {
                        dockerImage = "nodedev:${params.imageTag}"
                        containerName = "dev_container"
                    }
                    
                    // Stop and remove existing container
                    sh "docker stop ${containerName} || true"
                    sh "docker rm ${containerName} || true"
                    
                    // Run the application in Docker container
                    if (params.BRANCH == 'dev') {
                        sh "docker run -d --expose 3001 -p 3001:3000 --name ${containerName} hhkp/${dockerImage}"
                    } else {
                        sh "docker run -d --expose 3000 -p 3000:3000 --name ${containerName} hhkp/${dockerImage}"
                    }
                }
            }
        }
        stage('Scanning for vulnerabilities...'){
            steps {
                script{
                    def vulnerabilities = sh(script: "trivy image --exit-code 0 --severity HIGH,MEDIUM,LOW --no-progress hhkp/node${params.BRANCH}:${imageTag}", returnStdout: true).trim()
                    writeFile file: 'vulnerabilities.txt', text: vulnerabilities
                }
            }
        }
    }
    post {
        success {
            archiveArtifacts 'hadolint_lint.txt'
            archiveArtifacts 'vulnerabilities.txt'
        }
    }
}