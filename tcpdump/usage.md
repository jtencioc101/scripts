# AKS Connectivity Test and Packet Capture Script

This script automates network connectivity testing and packet capture on Azure Kubernetes Service (AKS). It creates a Kubernetes pod with two containers: one that runs connectivity tests (using `nc` for port checks) and another that runs `tcpdump` to capture network traffic. The packet capture file is then copied to the local machine for analysis.

## Features:
- Tests network connectivity to a specified endpoint and port.
- Captures network traffic on the same endpoint and port for the duration of the test.
- Copies the packet capture file (`.pcap`) to the local machine after the test completes.
- Removes the created pod and cleans up resources after the test finishes.

## Requirements:
- `kubectl`: Must be configured to interact with your AKS cluster.
- Access to your AKS cluster with sufficient permissions to create pods and run `tcpdump`.
- A Unix-based system (Linux or macOS) for running the script.

## How to Use:

### 1. Locate the script:
```bash
cd scripts/tcpdump
```

### 2. Make the script executable:
```bash
chmod +x tcpdump.sh
```

### 3. Run the script:
```bash
./tcpdump.sh
```

### 4. Follow the prompts:
- **Endpoint to test**: Enter the hostname or IP address you want to test (e.g., `example.com`).
- **Port to test**: Enter the port number to test (e.g., `80`).
- **Test duration**: Enter the number of seconds you want the test to run (e.g., `30`).

### 5. Result:
Once the test completes, you will receive a packet capture file (`capture.pcap`) in your current working directory. The file contains the network traffic captured during the test.

### 6. Cleanup:
The pod used for the test will automatically be deleted after the test is completed and the capture file has been copied.

## Script Flow:
1. The script prompts the user for the **endpoint**, **port**, and **duration** of the test.
2. It creates a Kubernetes pod on AKS with two containers:
   - One container runs `nc` (Netcat) to test connectivity to the specified endpoint and port.
   - The other container runs `tcpdump` to capture network traffic for the duration of the test.
3. The packet capture file is copied to the local machine after the test completes.
4. The pod is deleted, and resources are cleaned up.

## Example Output:
```bash
Enter the endpoint to test (e.g., example.com):
example.com
Enter the port to test (e.g., 80):
80
Enter the duration of the test in seconds (e.g., 30):
20
Creating pod...
Pod network-test-pod created successfully!
Test running for 20 seconds...
Copying capture file...
Packet capture file has been copied to your local machine: ./capture.pcap
Cleaning up pod...
Done!
```

## Notes:
- The script uses `tcpdump` to capture network traffic, which requires elevated privileges. The container running `tcpdump` has been granted the `NET_ADMIN` capability to allow packet capture.
- Ensure that your Kubernetes environment has the necessary permissions to run this script and capture network traffic.