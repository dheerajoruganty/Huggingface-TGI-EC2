#!/bin/sh
REGION=us-east-1
IMAGE_URI=763104351884.dkr.ecr.$REGION.amazonaws.com/huggingface-pytorch-tgi-inference:2.4.0-tgi2.3.1-gpu-py311-cu124-ubuntu22.04
CONTAINER_NAME=f1mbench_model_container
echo "Going to download model container"
echo "Content in docker command: $REGION, $IMAGE_URI, $CONTAINER_NAME"

# Login to AWS ECR and pull the Docker image
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $IMAGE_URI
docker pull $IMAGE_URI

# Run the new Docker container with specified settings
# shutdown existing docker compose
docker compose down

# Attempt to stop and remove the container up to 3 times if container exists
if [ -n "$(docker ps -aq --filter "name=HuggingfaceTGI")" ]; then
    for i in {1..3}; do
        echo "Attempt $i to stop and remove the container: HuggingfaceTGI"
        
        # Stop the container
        docker ps -q --filter "name=HuggingfaceTGI" | xargs -r docker stop
        
        # Wait for 5 seconds
        sleep 5
        
        # Remove the container
        docker ps -aq --filter "name=HuggingfaceTGI" | xargs -r docker rm
        
        # Wait for 5 seconds
        sleep 5
        
        # Check if the container is removed
        if [ -z "$(docker ps -aq --filter "name=HuggingfaceTGI")" ]; then
            echo "Container HuggingfaceTGI successfully stopped and removed."
            break
        else
            echo "Container HuggingfaceTGI still exists, retrying..."
        fi
    done
else
    echo "Container HuggingfaceTGI does not exist. No action taken."
fi

echo going to start the container, this will take about 10 minutes...
docker compose up -d
echo "started docker compose in daemon mode"
