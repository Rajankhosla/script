#!/bin/bash
#####Configuring isolate Network#####
gcloud compute --project=ximble-1 networks create ximble --subnet-mode=custom --bgp-routing-mode=global
#####Checking network is created or not#####
NETWORK=`gcloud compute networks list --filter ximble | awk '{print $1}' | grep -ie ximble`
if [ $NETWORK = ximble ]
then
echo "Network created successfully. Now working on Subnetworks"
else
echo "Issue with Netowrk creation. Please check configuration once."
fi
#####Configuring Subnetworks for network "Ximble"
gcloud beta compute --project=ximble-1 networks subnets create ximble-subnet --network=ximble --region=us-central1 --range=10.2.0.0/16 --enable-private-ip-google-access --enable-flow-logs
if [ $? -eq 0 ]
then
echo "Subnet created successfully under network ximble. Now applying firewall rules"
else
echo "Subnet not created. Please check configuration"
fi
#####Applying firewall rules#####
##allow rdp
gcloud compute --project=ximble-1 firewall-rules create allow-ximble --direction=INGRESS --priority=1000 --network=ximble --action=ALLOW --rules=tcp:3389 --source-ranges=75.75.104.21/32,61.12.91.58/32
sleep 15
if [ $? -eq 0 ]
then
echo "For rdp rule created successfully"
else
echo "Rule not created seems issue. Please check"
fi
##allow cache
gcloud compute --project=ximble-1 firewall-rules create ximble-allow-cache --direction=INGRESS --priority=1000 --network=ximble --action=ALLOW --rules=tcp:6379 --source-ranges=0.0.0.0/0
sleep 15
if [ $? -eq 0 ]
then
echo "For cache rule created succesfully"
else
echo "Rule not created seems issue. Please check"
fi
##allow http
gcloud compute --project=ximble-1 firewall-rules create ximble-allow-http --direction=INGRESS --priority=1000 --network=ximble --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0
sleep 15
if [ $? -eq 0 ]
then
echo "For http rule created succesfully"
else
echo "Rule not created seems issue. Please check"
fi
##allow https
gcloud compute --project=ximble-1 firewall-rules create ximble-allow-https --direction=INGRESS --priority=1000 --network=ximble --action=ALLOW --rules=tcp:443 --source-ranges=0.0.0.0/0
sleep 15
if [ $? -eq 0 ]
then
echo "For http rule created succesfully"
else
echo "Rule not created seems issue. Please check"
fi
##allow internal traffic
gcloud compute --project=ximble-1 firewall-rules create allow-internal --direction=INGRESS --priority=1000 --network=ximble --action=ALLOW --rules=all --source-ranges=10.2.0.0/16
sleep 15
if [ $? -eq 0 ]
then
echo "For internal traffic rule created succesfully"
else
echo "Rule not created seems issue. Please check"
fi

######Configuring health check######
gcloud compute --project "ximble-1" http-health-checks create "ximble-app-health-check" --port "80" --request-path "/" --check-interval "5" --timeout "5" --unhealthy-threshold "5" --healthy-threshold "1"
HEALTHCHECK=`gcloud compute http-health-checks list --filter ximble-app-health-check | awk '{print $1}' | grep -v NAME`
if [ $HEALTHCHECK = ximble-app-health-check ]
then
echo "Health check created sucessfully. Now working on Template"
else
echo "Problem with Health check configuration. Please check configuration once."
fi

#### Template creation from image####
gcloud beta compute --project=ximble-1 instance-templates create ximble-app-template --machine-type=n1-standard-2 --subnet=ximble-subnet --network-tier=STANDARD --region=us-central1 --image=image-app --image-project=ximble-1 --boot-disk-size=300GB --boot-disk-type=pd-ssd

sleep 30
##############list template 
template=`gcloud compute instance-templates list --filter ximble-app-template |awk '{print $1}' |grep -v NAME`
if [ $template = ximble-app-template ] 
then
echo "creating instance group in US-Central1-a"
gcloud compute --project "ximble-1" instance-groups managed create "ximble-app" --zone "us-central1-a" --base-instance-name "ximble-app" --template "ximble-app-template" --size "1"
sleep 30
echo "creating instance group in US central1-f"
gcloud compute --project "ximble-1" instance-groups managed create "ximble-app" --zone "us-central1-f" --base-instance-name "ximble-app" --template "ximble-app-template" --size "1"

else
echo "echo instance-templates not found"
fi

echo "checking if instance group has been created in US Central1-a"

INSTANCE_GROUP=`gcloud compute instance-groups list | awk '{print $2}'  |grep -v LOCATION | head  -n 1`

if [ $INSTANCE_GROUP = us-central1-a ]
then
echo "creating Autoscaling in US-Central1-a"
gcloud compute --project "ximble-1" instance-groups managed set-autoscaling "ximble-app" --zone "us-central1-a" --cool-down-period "60" --max-num-replicas "2" --min-num-replicas "1" --target-cpu-utilization "0.7000000000000001"

sleep 20
####Auto healing for instance group in zone "us-central1-a"####

gcloud beta compute instance-groups managed set-autohealing "ximble-app" --initial-delay "300" --http-health-check "ximble-app-health-check" --zone "us-central1-a"
else
echo "auto scaling can not be configurged as instance group not found"
fi

##############
INSTANCE_GROUP1=`gcloud compute instance-groups list | awk '{print $2}'  |grep -v LOCATION | awk END{print}`

if [ $INSTANCE_GROUP1 = us-central1-f ]
then
echo "creating Autoscaling in US-Central1-f"
gcloud compute --project "ximble-1" instance-groups managed set-autoscaling "ximble-app" --zone "us-central1-f" --cool-down-period "60" --max-num-replicas "2" --min-num-replicas "1" --target-cpu-utilization "0.7000000000000001"

sleep 20
####Auto healing for instance group in zone "us-central1-a"####

gcloud beta compute instance-groups managed set-autohealing "ximble-app" --initial-delay "300" --http-health-check "ximble-app-health-check" --zone "us-central1-f"
else
echo "auto scaling can not be configurged as instance group not found"
fi

#########Checking for Instance groups created or not

INSTANCE_GROUP_COUNT=`gcloud compute instance-groups list | awk '{print $1}' | grep -v NAME | wc -l`
if [ $INSTANCE_GROUP_COUNT = 2 ]
then 
echo "APP-Tier's has been created now working for DB-Tier's"
else
echo "There is some issue with APP-Tier's. Please check configuration once"
fi

####creating disk named as "ximble-db1"####
gcloud compute disks create db1-disk --zone=us-central1-a --type=pd-ssd --size=600GB
sleep 60
#############list disk
DISK1=`gcloud  compute disks list --filter db1-disk| awk '{print $1}' | grep -v NAME`
if [ $DISK1 = db1-disk ]
then
echo "creating First DB instance == ximble-db1"
gcloud compute instances create ximble-db1 --image image-db1 --image-project ximble-1 --zone us-central1-a --network ximble --subnet ximble-subnet  --no-address --local-ssd interface=SCSI --boot-disk-type=pd-ssd --disk=name=db1-disk,device-name=db1-disk,mode=rw,boot=no --machine-type=n1-standard-4
else
echo "Disk not found"
fi

#Creating DB2 instance
gcloud compute disks create db2-disk --zone=us-central1-f --type=pd-ssd --size=600GB
sleep 60
DISK2=`gcloud compute disks list |grep db2-disk |awk '{print $1}'`
if [ $DISK2 = db2-disk ]
then
echo "creating Second DB instance == ximble-db2"
gcloud compute instances create ximble-db2 --image image-db2 --image-project ximble-1 --zone us-central1-f --network ximble --subnet ximble-subnet  --no-address --local-ssd interface=SCSI --boot-disk-type=pd-ssd --disk=name=db2-disk,device-name=db2-disk,mode=rw,boot=no --machine-type=n1-standard-4
else
echo "Disk not found"
fi

#######Checking for DB instances created or not
DISK_COUNT=`gcloud compute instances list | awk '{print $1}' | grep -v NAME | grep -iE 'ximble-db1|ximble-db2' | wc -l`
if [ $DISK_COUNT = 2 ]
then
echo "DB instances created succesfully, Now Configuring Load-Balancer" 
else
echo "There is some issue with DB-Tier's. Please check configuration once"
fi

#####Configuring ports for instance group of zone "us-central1-a"#####
gcloud compute instance-groups set-named-ports ximble-app --named-ports http-port:80 --zone us-central1-a
if [ $? -eq 0 ]
then

#####For Creating Backend services#####
gcloud compute backend-services create ximble-backend-lb-01 --http-health-checks ximble-app-health-check --port-name http-port --protocol HTTP --global
else
echo "not running"
fi

#####For Adding instance-group of us-central1-a into backend services#####
BACKEND_SERVICES=`gcloud compute backend-services list | awk '{print $1}' | grep -v NAME`

if [ $BACKEND_SERVICES = ximble-backend-lb-01 ]
then
echo "Configuring Backend Services for zone us-central1-a"
gcloud compute backend-services add-backend ximble-backend-lb-01 --instance-group ximble-app --balancing-mode UTILIZATION --max-utilization 0.8 --capacity-scaler 1.0 --global --instance-group-zone=us-central1-a
else 
echo "not running"
fi
#####Configuring ports for instance group of zone "us-central1-f"#####

gcloud compute instance-groups set-named-ports ximble-app --named-ports http-port:80 --zone us-central1-f
if [ $? -eq 0 ]
then
echo "Configuring Backend Services for zone us-central1-f"
#####For Adding instance-group of us-central1-f into backend services#####
gcloud compute backend-services add-backend ximble-backend-lb-01 --instance-group ximble-app --balancing-mode UTILIZATION --max-utilization 0.8 --capacity-scaler 1.0 --global --instance-group-zone=us-central1-f
else
echo "not running"
fi

####Configuring hosts and path rules######

gcloud compute url-maps create ximble-global-lb-01 --default-service ximble-backend-lb-01
if [ $? -eq 0 ]
then
echo "Hosts and path rules are configured"
else
echo "backend services not found"
fi


#####HTTP-Proxy confgiuration for LB#####

gcloud compute target-http-proxies create http-proxy --url-map ximble-global-lb-01
if [ $? -eq 0 ]
then
echo "Load balanacer configuration completed"
else
echo "Load balancer not found"
fi

#####Configuring Frontend services######

gcloud beta compute forwarding-rules create ximble-frontend-lb-01 --region us-central1 --global-address --ports 80  --target-http-proxy http-proxy --network-tier=STANDARD --address=35.206.71.205
if [ $? -eq 0 ]
then
echo "Frontend services configuration completed"
else
echo "Issue with Frontend configuration"
fi







