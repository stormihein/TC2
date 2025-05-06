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

    /* -----------------------------------------------------------
       Install required CLIs (first run only, ~20-30 s).
       Uses static binaries → no sudo needed inside Jenkins.
       ---------------------------------------------------------- */
    stage('Install tooling') {
      steps {
        sh '''
          set -e

          # ------- Docker CLI -------
          if ! command -v docker >/dev/null ; then
            echo "[info] Installing Docker CLI"
            curl -sL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz |
              tar -xz --strip-components=1 docker/docker
            install -m 0755 docker /usr/local/bin/docker
          fi

          # ------- AWS CLI v2 -------
          if ! command -v aws >/dev/null ; then
            echo "[info] Installing AWS CLI v2"
            curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
            unzip -q awscliv2.zip
            ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
          fi

          # ------- kubectl -------
          if ! command -v kubectl >/dev/null ; then
            echo "[info] Installing kubectl"
            KVER=$(curl -sSL https://dl.k8s.io/release/stable.txt)
            curl -sL https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl -o kubectl
            install -m 0755 kubectl /usr/local/bin/kubectl
          fi
        '''
      }
    }

    stage('Build & Push image') {
      steps {
        withCredentials([usernamePassword(
            credentialsId: 'aws-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {

          sh '''
            set -e
            # Login to ECR
            aws ecr get-login-password --region $AWS_REGION | \
              docker login --username AWS --password-stdin $ECR_REPO

            # Build & push
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
            set -e
            # Update kubeconfig and roll out new image
            aws eks update-kubeconfig --region $AWS_REGION --name tc2-eks
            kubectl set image deployment/hello-world \
              hello-world=$ECR_REPO:$BUILD_NUMBER
          '''
        }
      }
    }
  }
}
