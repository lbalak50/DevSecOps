# This bash script uses Kubernetes to establish within Google cloud a multi-service sample application named hello.

# In a Goolge Cloud Console run this script using this command:
# bash <(curl -s https://raw.githubusercontent.com/wilsonmar/Dockerfiles/master/k8s-gcp-hello.sh)

# PROTIP: Define environment variable for use in several commands below:
bash <(curl -O https://raw.githubusercontent.com/wilsonmar/Dockerfiles/master/gcp-set-my-zone.sh)
# export MY_ZONE="us-central1-b"
# gcloud config set compute/zone ${MY_ZONE}
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# PROTIP: Use repo forked from googlecodelabs to ensure that this remains working:
git clone https://github.com/wilsonmar/orchestrate-with-kubernetes.git
cd orchestrate-with-kubernetes/kubernetes
ls

# cleanup.sh deployments  nginx  pods  services  tls
# Clean up (delete) what was created in previous session:
chmod +x cleanup.sh
./cleanup.sh
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# List what GKE clusters are left over from previous run:
gcloud compute instances list
   # NAME                                     ZONE           MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP      STATUS
   # gke-io-default-pool-c8cd677e-gfzq        us-central1-b  n1-standard-1               10.128.0.8   35.192.220.202   RUNNING
   # gke-io-default-pool-c8cd677e-nqrb        us-central1-b  n1-standard-1               10.128.0.7   35.202.233.114   RUNNING
   # gke-io-default-pool-c8cd677e-xhv8        us-central1-b  n1-standard-1               10.128.0.9   35.193.71.132    RUNNING
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# If they exist, delete them:
gcloud container clusters delete io --zone us-central1-b
   # The following clusters will be deleted.
   # - [io] in [us-central1-f]
   # Do you want to continue (Y/n)?  Y
   # Deleting cluster io...done.
   # Deleted [https://container.googleapis.com/v1/projects/cicd-182518/zones/us-central1-b/clusters/io].
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Start up a cluster:
gcloud container clusters create io
   # Response takes several minutes: Creating cluster io ...|
   # reating cluster io...done.
   # Created [https://container.googleapis.com/v1/projects/cicd-182518/zones/us-central1-b/clusters/io].
   # kubeconfig entry generated for io.
   # NAME  ZONE           MASTER_VERSION  MASTER_IP     MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
   # io    us-central1-b  1.7.8-gke.0     35.193.92.75  n1-standard-1  1.7.8-gke.0   3          RUNNING
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi
   
# Launch a single instance of the nginx container:
kubectl run nginx --image=nginx:1.10.0
   # deployment "nginx" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# View containers running in pods:
kubectl get pods
   # NAME                     READY     STATUS    RESTARTS   AGE
   # nginx-1803751077-wcb7d   1/1       Running   0          1m
   # See https://kubernetes.io/docs/concepts/workloads/pods/pod/
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Expose outside Kubernetes the nginx container through a LoadBalancer:
kubectl expose deployment nginx --port 80 --type LoadBalancer
   # service "nginx" exposed
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Run every minute until the EXTERNAL-IP goes from <pending>:
kubectl get services
   # NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
   # kubernetes   ClusterIP      10.7.240.1     <none>        443/TCP        20m
   # nginx        LoadBalancer   10.7.250.125   <pending>     80:30839/TCP   1m
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# View the HTML that comes back from calling the EXTERNAL-IP:
# curl http://<External IP>:80

# Create a single 10MB pod kelseyhightower's monolith image, listening on port 80, with a health UI on port 81:
kubectl create -f pods/monolith.yaml
   # pod "monolith" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# list pods running in the default namespace:
kubectl get pods
   # NAME                     READY     STATUS    RESTARTS   AGE
   # monolith                 1/1       Running   0          26s
   # nginx-1803751077-wcb7d   1/1       Running   0          1h
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Get information about pods named monolith:
kubectl describe pods monolith
   # This lists IP address (such as 10.4.0.4), Status, Containers, Conditions, Events.
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Map a local port to a port inside the monolith pod:

# Manually open a 2nd terminal (clicking the "+" to "Add Cloud Shell session") to set up port-forwarding:
kubectl port-forward monolith 10080:80
   # Forwarding from 127.0.0.1:10080 -> 80
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# In the 2nd terminal (Cloud Shell session) (in HOME folder) to talking to our pod:
# curl http://127.0.0.1:10080
   # {"message":"Hello"}
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Also on the 2nd terminal, hit a secure endpoint:
# curl http://127.0.0.1:10080/secure
   # authorization failed

# Because Cloud shell doesn't handle copying long strings well:
# In the 3rd terminal, Capture in an environment variable the token returned in response to manually log in:
TOKEN=$(curl http://127.0.0.1:10080/login -u user|jq -r '.token')
   # Enter host password for user 'user':
# Manually type in the (super-secret) password "password" to login.
   # Logging in caused a JWT token to print out
   # {"token":"eyJhbGci..."}
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Copy the token and use it to hit our secure endpoint with curl into an environment variable for use in the previous step.
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:10080/secure
   # {"message":"Hello"}
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# View app logs entries for the monolith Pod:
kubectl logs monolith
   # 2017/12/01 16:45:26 Starting server...
   # 2017/12/01 16:45:26 Health service listening on 0.0.0.0:81
   # 2017/12/01 16:45:26 HTTP service listening on 0.0.0.0:80
   # 127.0.0.1:52500 - - [Fri, 01 Dec 2017 16:55:19 UTC] "GET / HTTP/1.1" curl/7.38.0
   # 127.0.0.1:52630 - - [Fri, 01 Dec 2017 16:56:08 UTC] "GET /secure HTTP/1.1" curl/7.38.0
   # 127.0.0.1:52824 - - [Fri, 01 Dec 2017 16:57:26 UTC] "GET /login HTTP/1.1" curl/7.38.0
   # 127.0.0.1:53178 - - [Fri, 01 Dec 2017 16:59:43 UTC] "GET /login HTTP/1.1" curl/7.38.0
   # 127.0.0.1:53578 - - [Fri, 01 Dec 2017 17:02:24 UTC] "GET /secure HTTP/1.1" curl/7.38.0
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Manually open a 3rd terminal to use the -f flag to get a stream of the logs happening in real-time:
# kubectl logs -f monolith
   # Because this runs continuously, other commands cannot be entered on this terminal.

# Back on the 2nd terminal, interact with the monolith to see the logs updating (in terminal 3):
# curl http://127.0.0.1:10080

# Open an interactive shell inside the Monolith Pod to troubleshoot from within a container:
# kubectl exec monolith --stdin --tty -c monolith /bin/sh
   # The cursor changes to /# 
   
# Shell into the monolith container to see if we can test external connectivity:
# ping -c 3 google.com
   # ING google.com (209.85.200.101): 56 data bytes
   # 64 bytes from 209.85.200.101: seq=0 ttl=52 time=0.789 ms
   # 64 bytes from 209.85.200.101: seq=1 ttl=52 time=0.410 ms
   # 64 bytes from 209.85.200.101: seq=2 ttl=52 time=0.402 ms
   # --- google.com ping statistics ---
   # 3 packets transmitted, 3 packets received, 0% packet loss
   # round-trip min/avg/max = 0.402/0.533/0.789 ms

# Return:
# exit

# See http://kubernetes.io/docs/user-guide/services/

# Create secure-monolith pods and their configuration data:
kubectl create secret generic tls-certs --from-file tls/
   # secret "tls-certs" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi
   
kubectl create configmap nginx-proxy-conf --from-file nginx/proxy.conf
   # configmap "nginx-proxy-conf" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

kubectl create -f pods/secure-monolith.yaml
   # pod "secure-monolith" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Expose the secure-monolith Pod externally by creating a Kubernetes service using services/monolith.yaml:
# selector is used to automatically find and expose any pods with the labels "app=monolith" and "secure=enabled"
kubectl create -f services/monolith.yaml
   # service "monolith" created
   # See http://releases.k8s.io/release-1.2/docs/user-guide/services-firewalls.md
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi
   
# Allow traffic to the monolith service on the exposed nodeport:
gcloud compute firewall-rules create allow-monolith-nodeport \
  --allow=tcp:31000
   # Creating firewall ... Done
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

gcloud compute instances list
   # Creating firewall...|Created [https://www.googleapis.com/compute/v1/projects/cicd-182518/global/firewalls/allow-monolith-nodeport].
   # Creating firewall...done.
   # NAME                     NETWORK  DIRECTION  PRIORITY  ALLOW      DENY
   # allow-monolith-nodeport  default  INGRESS    1000      tcp:31000
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Try hitting the secure-monolith service:
# curl -k https://<EXTERNAL_IP>:31000

# By default the monolith service is not setup with endpoints. 
# Troubleshoot an issue like this is to use the kubectl get pods command with a label query.

# List pods running with the monolith label:
kubectl get pods -l "app=monolith"
   # AME              READY     STATUS    RESTARTS   AGE
   # monolith          1/1       Running   0          30m
   # secure-monolith   2/2       Running   0          2m
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# But what about "app=monolith" and "secure=enabled"?
kubectl get pods -l "app=monolith,secure=enabled"
   # No resources found.
   # This is because we need to add the "secure=enabled" label to them.
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Add "secure=enabled" label to the secure-monolith Pod. 
kubectl label pods secure-monolith 'secure=enabled'
   # pod "secure-monolith" labeled
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Check and see whether labels have been updated:
kubectl get pods secure-monolith --show-labels
   # NAME              READY     STATUS    RESTARTS   AGE       LABELS
   # secure-monolith   2/2       Running   0          6m        app=monolith,secure=enabled
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# View the list of endpoints on the monolith service:
kubectl describe services monolith | grep Endpoints
   # Endpoints: 10.4.1.6:443
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# See the rest of the info:
kubectl describe services monolith
   # Name:                     monolith
   # Namespace:                default
   # Labels:                   <none>
   # Annotations:              <none>
   # Selector:                 app=monolith,secure=enabled
   # Type:                     NodePort
   # IP:                       10.7.240.49
   # Port:                     <unset>  443/TCP
   # TargetPort:               443/TCP
   # NodePort:                 <unset>  31000/TCP
   # Endpoints:                10.4.1.6:443
   # Session Affinity:         None
   # External Traffic Policy:  Cluster
   # Events:                   <none>
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Obtain the EXTERNAL_IP for one of the gke nodes:
gcloud compute instances list
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# TODO: How to extract the EXTERNAL IP address into an environment variable?

# View:
# curl -k https://<EXTERNAL_IP>:31000

#### Deployment

# break the monolith app into three separate pieces:
   # auth - Generates JWT tokens for authenticated users.
   # hello - Greet authenticated users.
   # frontend - Routes traffic to the auth and hello services.
   # See http://kubernetes.io/docs/user-guide/deployments/#what-is-a-deployment

# Deploy 1 replica called "auth" from Kelsey:
kubectl create -f deployments/auth.yaml
   # deployment "auth" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Create a service for your auth deployment:
kubectl create -f services/auth.yaml
   # service "auth" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Create and expose the hello app Deployment:
kubectl create -f deployments/hello.yaml
   # deployment "hello" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

kubectl create -f services/hello.yaml
   # service "hello" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Create and expose the frontend Deployment:
kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf
   # configmap "nginx-frontend-conf" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

kubectl create -f deployments/frontend.yaml
   # deployment "frontend" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

kubectl create -f services/frontend.yaml
   # service "frontend" created
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Interact with the frontend by grabbing it's External IP and then curling to it:
kubectl get services frontend
   # NAME       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
   # frontend   LoadBalancer   10.7.247.150   <pending>     443:30738/TCP   25s
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# curl -k https://<EXTERNAL-IP>

# Delete using a script:
chmod +x cleanup.sh
./cleanup.sh
   # pod "monolith" deleted
   # pod "secure-monolith" deleted
   # Error from server (NotFound): pods "healthy-monolith" not found
   # service "monolith" deleted
   # service "auth" deleted
   # service "frontend" deleted
   # service "hello" deleted
   # deployment "auth" deleted
   # deployment "frontend" deleted
   # deployment "hello" deleted
   # Error from server (NotFound): deployments.extensions "hello-canary" not found
   # Error from server (NotFound): deployments.extensions "hello-green" not found
   # secret "tls-certs" deleted
   # configmap "nginx-frontend-conf" deleted
   # configmap "nginx-proxy-conf" deleted
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

gcloud -q container clusters delete io --zone ${MY_ZONE}
   # PROTIP: -q automatically responds with default answer capitalized (Y=yes), which avoids a pause for manual attention.
   # The following clusters will be deleted.
   #  - [io] in [us-central1-b]
   # Do you want to continue (Y/n)?  Y
   # Deleting cluster io...done.
   # Deleted [https://container.googleapis.com/v1/projects/cicd-182518/zones/us-central1-b/clusters/io].
   if [ $? -eq 0 ]; then echo OK else echo FAIL fi

# Remove Git repository:
cd ..
cd ..
rm -rf orchestrate-with-kubernetes


