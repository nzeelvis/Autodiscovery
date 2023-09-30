pipeline {
    agent any
    environment {
        DOCKER_USER     = credentials('docker-user')
        DOCKER_PASSWORD = credentials('docker-pwd')
    }
    stages {
        stage('Build Artifact') {
            steps {
                sh 'mvn -f pom.xml clean package'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t cloudhight/testapp:lastest .'
            }
        }
        stage('Docker Login') {
            steps {
                sh 'docker login --username $DOCKER_USER --password $DOCKER_PASSWORD'
            }
        }
        stage('Pushing Docker Image to Docker hub') {
            steps {
                sh 'docker push cloudhight/testapp:latest'
            }
        }
        stage('Deploying image into dockerhost'){
            steps {
                 sshagent (['jenkins-key']) {
                   sh 'ssh -t -t ec2-user@10.0.3.70 -o strictHostKeyChecking=no "cd /etc/ansible && ansible-playbook MyPlaybook.yaml"'
                }
            }
        }
    }
}
