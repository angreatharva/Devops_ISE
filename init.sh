#!/bin/bash
# Abstergo Application Initialization Script
# This script sets up the project and can trigger Jenkins builds

# Set default values
SETUP_ONLY=false
TRIGGER_JENKINS=false
BUILD_IMAGES=false
JENKINS_URL="http://localhost:8080"
JENKINS_JOB="abstergo-app"
JENKINS_TOKEN=""

# Print banner
echo "==============================================="
echo "  Abstergo Application - Initialization Script  "
echo "==============================================="
echo

# Function to show help
show_help() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -s, --setup-only        Only setup the project, don't run anything"
  echo "  -b, --build-images      Build Docker images after setup"
  echo "  -j, --jenkins           Trigger Jenkins build after setup"
  echo "  -u, --jenkins-url URL   Jenkins URL (default: http://localhost:8080)"
  echo "  -n, --job-name NAME     Jenkins job name (default: abstergo-app)"
  echo "  -t, --token TOKEN       Jenkins API token for triggering builds"
  echo "  -h, --help              Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -s|--setup-only)
      SETUP_ONLY=true
      shift
      ;;
    -b|--build-images)
      BUILD_IMAGES=true
      shift
      ;;
    -j|--jenkins)
      TRIGGER_JENKINS=true
      shift
      ;;
    -u|--jenkins-url)
      JENKINS_URL="$2"
      shift 2
      ;;
    -n|--job-name)
      JENKINS_JOB="$2"
      shift 2
      ;;
    -t|--token)
      JENKINS_TOKEN="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Ensure scripts are executable
echo "Ensuring scripts are executable..."
chmod +x scripts/*.sh

# Verify setup
echo "Verifying project setup..."
./scripts/verify.sh

# If setup only, exit here
if [ "$SETUP_ONLY" = true ]; then
  echo "Setup completed successfully. Exiting as requested."
  exit 0
fi

# Build Docker images if requested
if [ "$BUILD_IMAGES" = true ]; then
  echo "Building Docker images..."
  ./scripts/build-images.sh
  echo "Docker images built successfully."
  exit 0
fi

# Trigger Jenkins build if requested
if [ "$TRIGGER_JENKINS" = true ]; then
  echo "Triggering Jenkins build..."
  
  # Check if token is provided
  if [ -z "$JENKINS_TOKEN" ]; then
    echo "Error: Jenkins API token is required for triggering builds."
    echo "Please provide a token using the -t or --token option."
    exit 1
  fi
  
  # Call the jenkins-build.sh script
  ./scripts/jenkins-build.sh --url "$JENKINS_URL" --job "$JENKINS_JOB" --token "$JENKINS_TOKEN" --wait
  
  echo "Jenkins build triggered successfully."
  exit 0
fi

# If we get here, run the application locally
echo "Starting local development environment..."

# Check if npm is available
if ! command -v npm &> /dev/null; then
  echo "Error: npm is not installed. Please install Node.js and npm first."
  exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Start the application
echo "Starting the application in development mode..."
npm run dev 