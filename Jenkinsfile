// Multibranch Pipeline
@Library('jenkins-github-deploy-lib@main') _
pipeline {
    agent any

    tools { nodejs "node" }
    environment {
        registry="hhkp"
        imageTag="v1.0"
    }
    stages {
        stage('Checkout SCM...') {
            steps {
                // Checkout the multibranch Git repository
                script {
                    checkoutStep('https://github.com/HHKP1/cicd-pipeline.git', ['main', 'dev'])
                    // checkout([$class: 'GitSCM', branches: [[name: 'main'], [name: 'dev']], userRemoteConfigs: [[url: 'https://github.com/HHKP1/cicd-pipeline.git']]])
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
                script {
                    buildStep(this)
                }
            }
        }
        stage('Test...') {
            steps {
                script {
                    testStep(this)
                }
            }
        }
        stage('Docker build...') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        sh "mv src/red_logo.svg src/logo.svg"
                        dockerBuildStep(this, 'hhkp', 'Dockerfile.tpl', 'nodemain', 'v1.0', '7.8.0-alpine', 3000)
                    } else if (env.BRANCH_NAME == 'dev' ) {
                        sh "mv src/orange_logo.svg src/logo.svg"
                        dockerBuildStep(this, 'hhkp', 'Dockerfile.tpl', 'nodedev', 'v1.0', '7.8.0-alpine', 3001)
                    }
                    // // Login to Docker Hub using access token
                    // withCredentials([string(credentialsId: 'docker-access-token', variable: 'DOCKER_ACCESS_TOKEN')]) {
                    //     sh "echo ${DOCKER_ACCESS_TOKEN} | docker login --username hhkp --password-stdin"
                    //     sh "docker build -t hhkp/node${env.BRANCH_NAME}:${env.imageTag} ."
                    //     sh "docker push hhkp/node${env.BRANCH_NAME}:${env.imageTag}"
                    // }
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