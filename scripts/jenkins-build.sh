#!/bin/bash
# Script to trigger Jenkins builds programmatically
# This can be used for automated CI/CD pipeline management

# Default values
JENKINS_URL=${JENKINS_URL:-"http://localhost:8080"}
JOB_NAME=${JOB_NAME:-"abstergo-app"}
JENKINS_USER=${JENKINS_USER:-"admin"}
JENKINS_API_TOKEN=${JENKINS_API_TOKEN:-""}
POLL_INTERVAL=${POLL_INTERVAL:-5}

# Help function
show_help() {
  echo "Jenkins Build Script for Abstergo Application"
  echo
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -u, --url URL              Jenkins URL (default: http://localhost:8080)"
  echo "  -j, --job JOB_NAME         Jenkins job name (default: abstergo-app)"
  echo "  -t, --token TOKEN          Jenkins API token"
  echo "  -p, --poll                 Enable Poll SCM trigger"
  echo "  -w, --wait                 Wait for build to complete"
  echo "  -c, --create               Create the job if it doesn't exist"
  echo "  -h, --help                 Show this help message"
  echo
  echo "Examples:"
  echo "  $0 --url http://jenkins:8080 --job abstergo-app --token YOUR_API_TOKEN"
  echo "  $0 --poll --wait           # Trigger Poll SCM and wait for completion"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -u|--url)
      JENKINS_URL="$2"
      shift 2
      ;;
    -j|--job)
      JOB_NAME="$2"
      shift 2
      ;;
    -t|--token)
      JENKINS_API_TOKEN="$2"
      shift 2
      ;;
    -p|--poll)
      ENABLE_POLL=true
      shift
      ;;
    -w|--wait)
      WAIT_FOR_COMPLETION=true
      shift
      ;;
    -c|--create)
      CREATE_JOB=true
      shift
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

# Check for required parameters
if [ -z "$JENKINS_API_TOKEN" ]; then
  echo "Error: Jenkins API token is required."
  echo "You can obtain this token from your Jenkins user configuration page."
  exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
  echo "Error: curl is not installed. Please install it first."
  exit 1
fi

# Function to enable Poll SCM trigger
enable_poll_scm() {
  echo "Enabling Poll SCM trigger for job $JOB_NAME..."
  
  # Get current job config
  CONFIG_XML=$(curl -s -u "$JENKINS_USER:$JENKINS_API_TOKEN" "$JENKINS_URL/job/$JOB_NAME/config.xml")
  
  # Check if triggers already exist
  if echo "$CONFIG_XML" | grep -q "<triggers>"; then
    # Update existing triggers
    NEW_CONFIG=$(echo "$CONFIG_XML" | sed '/<triggers>/a\    <hudson.triggers.SCMTrigger>\n      <spec>H/5 * * * *</spec>\n      <ignorePostCommitHooks>false</ignorePostCommitHooks>\n    </hudson.triggers.SCMTrigger>')
  else
    # Add triggers section
    NEW_CONFIG=$(echo "$CONFIG_XML" | sed '/<\/properties>/a\  <triggers>\n    <hudson.triggers.SCMTrigger>\n      <spec>H/5 * * * *</spec>\n      <ignorePostCommitHooks>false</ignorePostCommitHooks>\n    </hudson.triggers.SCMTrigger>\n  </triggers>')
  fi
  
  # Update job config
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$JENKINS_USER:$JENKINS_API_TOKEN" -X POST -d "$NEW_CONFIG" -H "Content-Type: application/xml" "$JENKINS_URL/job/$JOB_NAME/config.xml")
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "Poll SCM trigger enabled successfully."
  else
    echo "Failed to enable Poll SCM trigger. HTTP code: $HTTP_CODE"
    exit 1
  fi
}

# Function to create a new job if it doesn't exist
create_job() {
  # Check if job exists
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$JENKINS_USER:$JENKINS_API_TOKEN" "$JENKINS_URL/job/$JOB_NAME/")
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "Job $JOB_NAME already exists."
    return 0
  fi
  
  echo "Creating job $JOB_NAME..."
  
  # Create basic pipeline job
  JOB_CONFIG='<?xml version="1.0" encoding="UTF-8"?>
<flow-definition plugin="workflow-job">
  <description>Abstergo Application Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/yourusername/abstergo-app.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
</flow-definition>'
  
  # Create the job
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$JENKINS_USER:$JENKINS_API_TOKEN" -X POST -d "$JOB_CONFIG" -H "Content-Type: application/xml" "$JENKINS_URL/createItem?name=$JOB_NAME")
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "Job created successfully."
  else
    echo "Failed to create job. HTTP code: $HTTP_CODE"
    exit 1
  fi
}

# Function to trigger a build
trigger_build() {
  echo "Triggering build for job $JOB_NAME..."
  
  # Trigger build
  RESPONSE=$(curl -s -u "$JENKINS_USER:$JENKINS_API_TOKEN" -X POST "$JENKINS_URL/job/$JOB_NAME/build")
  
  # Check queue location
  QUEUE_URL=$(curl -s -u "$JENKINS_USER:$JENKINS_API_TOKEN" -X POST -I "$JENKINS_URL/job/$JOB_NAME/build" | grep -i location | awk '{print $2}')
  
  echo "Build queued at: $QUEUE_URL"
  QUEUE_ID=$(echo "$QUEUE_URL" | awk -F '/' '{print $NF}' | tr -d '\r')
  
  # Wait for the build to start if requested
  if [ "$WAIT_FOR_COMPLETION" = "true" ]; then
    wait_for_build "$QUEUE_ID"
  fi
}

# Function to wait for build completion
wait_for_build() {
  QUEUE_ID=$1
  echo "Waiting for build to start..."
  
  # Poll until the build starts
  BUILD_NUMBER=""
  while [ -z "$BUILD_NUMBER" ]; do
    sleep $POLL_INTERVAL
    BUILD_NUMBER=$(curl -s -u "$JENKINS_USER:$JENKINS_API_TOKEN" "$JENKINS_URL/queue/item/$QUEUE_ID/api/json" | grep -o '"executable":{"number":[0-9]*' | grep -o '[0-9]*')
    
    if [ -n "$BUILD_NUMBER" ]; then
      echo "Build #$BUILD_NUMBER started"
      break
    fi
    
    echo "Still waiting..."
  done
  
  # Poll until the build completes
  echo "Waiting for build #$BUILD_NUMBER to complete..."
  while true; do
    sleep $POLL_INTERVAL
    BUILD_RESULT=$(curl -s -u "$JENKINS_USER:$JENKINS_API_TOKEN" "$JENKINS_URL/job/$JOB_NAME/$BUILD_NUMBER/api/json" | grep -o '"result":"[A-Z]*' | cut -d '"' -f 4)
    
    if [ -n "$BUILD_RESULT" ]; then
      if [ "$BUILD_RESULT" = "SUCCESS" ]; then
        echo "Build #$BUILD_NUMBER completed successfully."
      else
        echo "Build #$BUILD_NUMBER failed with result: $BUILD_RESULT"
        exit 1
      fi
      break
    fi
    
    echo "Still building..."
  done
  
  # Print build log
  echo "Build log:"
  curl -s -u "$JENKINS_USER:$JENKINS_API_TOKEN" "$JENKINS_URL/job/$JOB_NAME/$BUILD_NUMBER/consoleText"
}

# Main execution

# Create job if requested
if [ "$CREATE_JOB" = "true" ]; then
  create_job
fi

# Enable Poll SCM if requested
if [ "$ENABLE_POLL" = "true" ]; then
  enable_poll_scm
fi

# Trigger build
trigger_build 