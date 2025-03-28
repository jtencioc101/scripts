#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'  # No Color

# Spinner function
spin() {
    local sp="/-\|"
    while true; do
        for i in {1..4}; do
            echo -ne "\r$1 ${sp:i-1:1}"
            sleep 0.1
        done
    done
}

# Prompt the user for input
echo -e "${CYAN}Enter the endpoint to test (e.g., example.com):${NC}"
read endpoint

echo -e "${CYAN}Enter the port to test (e.g., 80):${NC}"
read port

# Check if input is valid
if [[ -z "$endpoint" || -z "$port" ]]; then
    echo -e "${RED}Endpoint and port are required!${NC}"
    exit 1
fi

# Prompt the user for the duration of the test in seconds
echo -e "${CYAN}Enter the duration of the test in seconds (e.g., 30):${NC}"
read duration

# Check if the duration is a valid number
if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Duration must be a positive integer!${NC}"
    exit 1
fi

# Set the names of the containers and pod
POD_NAME="network-test-pod"
CONTAINER_CONNECTIVITY="connectivity-container"
CONTAINER_TCPDUMP="tcpdump-container"
CAPTURE_FILE="capture.pcap"
VOLUME_NAME="capture-volume"
MOUNT_PATH="/capture-data"

# Spinner for applying the pod
echo -e "${YELLOW}Creating pod...${NC}"
spin "Applying pod configuration..." &
SPINNER_PID=$!
cat <<EOF > /tmp/network-test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
spec:
  volumes:
    - name: $VOLUME_NAME
      emptyDir: {}
  containers:
    - name: $CONTAINER_CONNECTIVITY
      image: busybox
      command: ["/bin/sh", "-c", "timeout $duration sh -c 'while true; do nc -zv $endpoint $port; sleep 5; done'"]
      volumeMounts:
        - name: $VOLUME_NAME
          mountPath: $MOUNT_PATH
    - name: $CONTAINER_TCPDUMP
      image: nicolaka/netshoot
      command: ["/bin/sh", "-c", "timeout $duration tcpdump -i eth0 port $port and host $endpoint -w $MOUNT_PATH/$CAPTURE_FILE"]
      volumeMounts:
        - name: $VOLUME_NAME
          mountPath: $MOUNT_PATH
      securityContext:
        capabilities:
          add: ["NET_ADMIN"]
EOF

# Apply the Kubernetes pod configuration from the temporary file
kubectl apply -f /tmp/network-test-pod.yaml
kill $SPINNER_PID
echo -e "${GREEN}Pod $POD_NAME created successfully!${NC}"

# Wait for the test duration to pass
echo -e "${CYAN}Test running for $duration seconds...${NC}"
sleep $duration

# Spinner for copying the capture file
echo -e "${YELLOW}Copying capture file...${NC}"
spin "Copying capture file..." &
SPINNER_PID=$!
kubectl cp $POD_NAME:$MOUNT_PATH/$CAPTURE_FILE ./capture.pcap
kill $SPINNER_PID
echo -e "${GREEN}Packet capture file has been copied to your local machine: ./capture.pcap${NC}"

# Clean up the pod
echo -e "${PURPLE}Cleaning up pod...${NC}"
kubectl delete pod $POD_NAME --force >/dev/null 2>&1

# Clean up the temporary YAML file
rm /tmp/network-test-pod.yaml

echo -e "${CYAN}Done!${NC}"
