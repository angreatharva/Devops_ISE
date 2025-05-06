# Setting Up Jenkins with Kubernetes Access

This guide explains how to set up your Jenkins server to properly access a Kubernetes cluster, which is needed for the deployment stage of the pipeline.

## Problem

If you're seeing the following error in your Jenkins pipeline:

```
* unable to read client-cert /home/atharva/.minikube/profiles/minikube/client.crt for minikube due to open /home/atharva/.minikube/profiles/minikube/client.crt: permission denied
* unable to read client-key /home/atharva/.minikube/profiles/minikube/client.key for minikube due to open /home/atharva/.minikube/profiles/minikube/client.key: permission denied
* unable to read certificate-authority /home/atharva/.minikube/ca.crt for minikube due to open /home/atharva/.minikube/ca.crt: permission denied
```

This means that the Jenkins user doesn't have access to the Kubernetes configuration and certificates needed to connect to your Minikube cluster.

## Solution

### Option 1: Use the Configuration Script

We've included a script that will set up all necessary files and permissions automatically:

1. Log in to your Jenkins server as root or a user with sudo privileges
2. Navigate to the project directory
3. Run the configuration script:

```bash
# Make the script executable
chmod +x configure_k8s_access.sh

# Run the script as root
sudo ./configure_k8s_access.sh
```

4. Restart Jenkins after making these changes:

```bash
sudo systemctl restart jenkins
```

### Option 2: Manual Configuration

If you prefer to configure things manually, follow these steps:

1. Log in to your Jenkins server as root or a user with sudo privileges
2. Create the necessary directories:

```bash
# Create directories
mkdir -p /var/lib/jenkins/.kube
mkdir -p /var/lib/jenkins/.minikube/profiles/minikube
```

3. Copy Minikube certificates (if using Minikube):

```bash
# Copy Minikube certificates
cp -f /home/atharva/.minikube/ca.crt /var/lib/jenkins/.minikube/
cp -f /home/atharva/.minikube/profiles/minikube/client.* /var/lib/jenkins/.minikube/profiles/minikube/
```

4. Create a kubeconfig file:

```bash
# Create the kubeconfig file with proper configuration
kubectl config view --flatten --minify > /var/lib/jenkins/.kube/config

# OR for Minikube, you can copy the user's config
cp -f /home/atharva/.kube/config /var/lib/jenkins/.kube/config
```

5. Set proper permissions:

```bash
# Set file permissions
chmod -R 644 /var/lib/jenkins/.minikube/ca.crt
chmod -R 644 /var/lib/jenkins/.minikube/profiles/minikube/client.crt
chmod -R 600 /var/lib/jenkins/.minikube/profiles/minikube/client.key
chmod 600 /var/lib/jenkins/.kube/config

# Set ownership
chown -R jenkins:jenkins /var/lib/jenkins/.minikube
chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

6. Restart Jenkins:

```bash
sudo systemctl restart jenkins
```

### Option 3: Use Kubernetes Service Account (Recommended for Production)

For production environments, it's better to use a dedicated Kubernetes Service Account:

1. Create a service account and role binding in your Kubernetes cluster:

```bash
# Create service account
kubectl create serviceaccount jenkins

# Create cluster role binding
kubectl create clusterrolebinding jenkins-admin --serviceaccount=default:jenkins --clusterrole=cluster-admin

# Get the token
kubectl get secret $(kubectl get serviceaccount jenkins -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode
```

2. Create a kubeconfig file for Jenkins using this token (save to `/var/lib/jenkins/.kube/config`)

3. Set proper permissions:

```bash
chmod 600 /var/lib/jenkins/.kube/config
chown jenkins:jenkins /var/lib/jenkins/.kube/config
```

## Additional Notes

- Make sure Minikube is running when you run the Jenkins pipeline
- The Jenkins user needs to have access to both Docker and kubectl commands
- If running Jenkins in a Docker container, you may need to mount the appropriate directories

## Troubleshooting

If you're still having issues:

1. Check if Minikube is running: `minikube status`
2. Test kubectl access from the Jenkins user:
   ```bash
   sudo -u jenkins kubectl get nodes
   ```
3. Verify environment variables in the Jenkins pipeline:
   ```
   KUBECONFIG=/var/lib/jenkins/.kube/config
   ```

## For Windows Users

If you're running Jenkins on Windows, adjust the paths accordingly and use appropriate Windows commands for setting permissions. 