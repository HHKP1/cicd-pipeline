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
                    checkoutStep(this, 'https://github.com/HHKP1/cicd-pipeline.git')
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
                    def imageName = env.BRANCH_NAME == 'dev' ? 'nodedev' : 'nodemain'
                    def containerName = env.BRANCH_NAME == 'dev' ? 'dev_container' : 'main_container'
                    def logoName = env.BRANCH_NAME == 'dev' ? 'orange_logo' : 'red_logo'
                    sh "mv src/${logoName}.svg src/logo.svg"
                    // if (env.BRANCH_NAME == 'main') {
                    //     imageName = nodemain
                    //     containerName = main_container
                    // } else if (env.BRANCH_NAME == 'dev' ) {
                    //     imageName = nodedev
                    //     containerName = dev_container
                    //     sh "mv src/orange_logo.svg src/logo.svg"
                    // }
                }
                dockerBuildStep(this, 'hhkp', containerName, 'Dockerfile.tpl', imageName, 'v1.0', '7.8.0-alpine', 3000)
            }
        }
        stage('Deploy...') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        deployStep(this, 'hhkp', 'nodemain', 'v1.0', 'main_container', 3000, 3000)
                    } else if (env.BRANCH_NAME == 'dev' ) {
                        deployStep(this, 'hhkp', 'nodedev', 'v1.0', 'dev_container', 3001, 3000)
                    }
                    // def dockerImage = "nodemain:${env.imageTag}"
                    // def containerName = "main_container"
                    
                    // if (env.BRANCH_NAME == 'dev') {
                    //     dockerImage = "nodedev:${env.imageTag}"
                    //     containerName = "dev_container"
                    // }
                    
                    // // Stop and remove existing container
                    // sh "docker stop ${containerName} || true"
                    // sh "docker rm ${containerName} || true"
                    
                    // // Run the application in Docker container
                    // if (env.BRANCH_NAME == 'dev') {
                    //     sh "docker run -d --expose 3001 -p 3001:3000 --name ${containerName} hhkp/${dockerImage}"
                    // } else {
                    //     sh "docker run -d --expose 3000 -p 3000:3000 --name ${containerName} hhkp/${dockerImage}"
                    // }
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
