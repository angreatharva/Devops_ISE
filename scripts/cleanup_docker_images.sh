#!/bin/bash
# Script to clean up old Docker images to free up system resources

echo "=== Abstergo Docker Image Cleanup Tool ==="
echo ""

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker command not found. Make sure Docker is installed."
    exit 1
fi

echo "This script will help you clean up old Docker images to free up disk space."
echo "It will keep the latest 3 versions of each image and remove older versions."
echo ""

# Function to cleanup images for a specific repository
cleanup_repo() {
    local REPO=$1
    echo "Processing repository: $REPO"
    
    # Get image IDs and tags sorted by creation date (oldest first)
    IMAGE_LIST=$(docker images --format "{{.ID}} {{.Tag}}" "$REPO" | sort -k2nr)
    
    # Count images
    IMAGE_COUNT=$(echo "$IMAGE_LIST" | wc -l)
    
    echo "Found $IMAGE_COUNT images for $REPO"
    
    # If we have 3 or fewer images, don't delete any
    if [ "$IMAGE_COUNT" -le 3 ]; then
        echo "Keeping all images (3 or fewer present)"
        return
    fi
    
    # Keep track of how many we've seen and kept
    KEEP_COUNT=0
    
    # Keep the latest 3, delete the rest
    echo "$IMAGE_LIST" | while read -r IMAGE_ID TAG; do
        KEEP_COUNT=$((KEEP_COUNT+1))
        
        if [ "$KEEP_COUNT" -gt 3 ] && [[ "$TAG" =~ ^[0-9]+$ ]]; then
            echo "Removing $REPO:$TAG (ID: $IMAGE_ID)"
            docker rmi "$REPO:$TAG" >/dev/null
        else
            echo "Keeping $REPO:$TAG"
        fi
    done
}

# List repositories to clean up
REPOS=("angreatharva/abstergo" "angreatharva/abstergo-metrics")

# Clean up each repository
for REPO in "${REPOS[@]}"; do
    echo ""
    echo "=== Processing $REPO ==="
    cleanup_repo "$REPO"
done

echo ""
echo "=== Cleanup Complete ==="
echo "Docker image space usage before:"
BEFORE=$(docker system df -v | grep "Images space usage")
echo "$BEFORE"

# Also prune any dangling images
echo ""
echo "Removing dangling images..."
docker image prune -f >/dev/null

echo ""
echo "Docker image space usage after:"
AFTER=$(docker system df -v | grep "Images space usage")
echo "$AFTER"

echo ""
echo "All done! Your system should have more free space now." 