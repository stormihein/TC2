pipeline {
  agent any

  environment {
    AWS_REGION = 'us-east-1'
    ECR_REPO   = '160140672552.dkr.ecr.us-east-1.amazonaws.com/tc2-hello-world'
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Push') {
      steps {
        // install Docker + AWS CLI on first run (fast on subsequent runs)
        sh '''
          if ! command -v docker >/dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq docker.io
          fi

          if ! command -v aws >/dev/null; then
            curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
            unzip -q awscliv2.zip
            sudo ./aws/install
          fi
        '''

        withCredentials([usernamePassword(
            credentialsId: 'aws-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {

          sh '''
            aws ecr get-login-password --region $AWS_REGION | \
              docker login --username AWS --password-stdin $ECR_REPO

            docker buildx build --platform linux/amd64 \
              -t $ECR_REPO:$BUILD_NUMBER .
            docker push $ECR_REPO:$BUILD_NUMBER
          '''
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        withCredentials([usernamePassword(
            credentialsId: 'aws-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {

          sh '''
            aws eks update-kubeconfig --region $AWS_REGION --name tc2-eks

            kubectl set image deployment/hello-world \
              hello-world=$ECR_REPO:$BUILD_NUMBER
          '''
        }
      }
    }
  }
}
