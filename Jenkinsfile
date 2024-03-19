// Multibranch Pipeline
@Library('jenkins-github-deploy-lib@main')
pipeline {
    agent any

    tools { nodejs "node" }
    environment {
        imageTag="v1.0"
    }
    stages {
        stage('Checkout SCM...') {
            steps {
                // Checkout the multibranch Git repository
                script {
                    checkoutStage('https://github.com/HHKP1/cicd-pipeline.git', ['main', 'dev'])
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
                script {
                    if (env.BRANCH_NAME == 'main') {
                        sh "mv src/red_logo.svg src/logo.svg"
                    } else if (env.BRANCH_NAME == 'dev' ) {
                        sh "mv src/orange_logo.svg src/logo.svg"
                    }
                    // Login to Docker Hub using access token
                    withCredentials([string(credentialsId: 'docker-access-token', variable: 'DOCKER_ACCESS_TOKEN')]) {
                        sh "echo ${DOCKER_ACCESS_TOKEN} | docker login --username hhkp --password-stdin"
                        sh "docker build -t hhkp/node${env.BRANCH_NAME}:${env.imageTag} ."
                        sh "docker push hhkp/node${env.BRANCH_NAME}:${env.imageTag}"
                    }
                }
            }
        }
        stage('Deploy...') {
            steps {
                script {
                    def dockerImage = "nodemain:${env.imageTag}"
                    def containerName = "main_container"
                    
                    if (env.BRANCH_NAME == 'dev') {
                        dockerImage = "nodedev:${env.imageTag}"
                        containerName = "dev_container"
                    }
                    
                    // Stop and remove existing container
                    sh "docker stop ${containerName} || true"
                    sh "docker rm ${containerName} || true"
                    
                    // Run the application in Docker container
                    if (env.BRANCH_NAME == 'dev') {
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
                    def vulnerabilities = sh(script: "trivy image --exit-code 0 --severity HIGH,MEDIUM,LOW --no-progress hhkp/node${env.BRANCH_NAME}:${imageTag}", returnStdout: true).trim()
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