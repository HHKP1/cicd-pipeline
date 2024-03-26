// Multibranch Pipeline
@Library('jenkins-github-deploy-lib@main') _

def branch = env.BRANCH_NAME == 'dev' ? 'dev' : 'main'
def imageName = env.BRANCH_NAME == 'dev' ? 'nodedev' : 'nodemain'
def containerName = env.BRANCH_NAME == 'dev' ? 'dev_container' : 'main_container'
def hostPort = env.BRANCH_NAME == 'dev' ? 3001 : 3000
def logoName = env.BRANCH_NAME == 'dev' ? 'orange_logo' : 'red_logo'

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
                    checkoutStep(this, branch, 'https://github.com/HHKP1/cicd-pipeline.git')
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
                    sh "mv src/${logoName}.svg src/logo.svg"
                    dockerBuildStep(this, registry, containerName, imageName, 'v1.0')
                }
            }
        }
        stage('Scanning for vulnerabilities...'){
            steps {
                script{
                    def vulnerabilities = sh(script: "trivy image --exit-code 0 --severity HIGH,MEDIUM,LOW --no-progress ${registry}/${imageName}:${imageTag}", returnStdout: true).trim()
                    writeFile file: 'vulnerabilities.txt', text: vulnerabilities
                }
            }
        }
    }
    post {
        success {
            archiveArtifacts 'hadolint_lint.txt'
            archiveArtifacts 'vulnerabilities.txt'
            
            script {
                def deployBranch = branch == 'dev' ? 'Deploy_to_dev' : 'Deploy_to_main'
                build job: deployBranch, parameters[string(name: 'REGISTRY', value: registry), string(name: 'IMG_NAME', value: imageName), string(name: 'CONTAINER_NAME', value: containerName), [$class: 'IntegerParameterValue', name: 'HOST_PORT', value: hostPort]]
            }
        }
    }
}