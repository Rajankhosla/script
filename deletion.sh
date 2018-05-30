#!/bin/bash
#####Forwarding Rules (Frontend)#####
gcloud compute forwarding-rules delete ximble-frontend-lb-01 --region us-central1 -q
if [ $? -eq 0 ]
then
echo "Frontend services deleted"
else
echo "Issue with Frontend Services deletion. Please check form console once."
fi
#####Target Proxy######
gcloud compute target-http-proxies delete http-proxy -q
if [ $? -eq 0 ]
then
echo "Target proxies deleted"
else
echo "Issue with Target proxies deletion. Please check form console once."
fi
#####URL Maps#####
gcloud compute url-maps delete ximble-global-lb-01 -q
if [ $? -eq 0 ]
then
echo "URL Maps deleted"
else
echo "Issue with URL Maps deletion. Please check form console once."
fi
#####Backend#####
gcloud compute backend-services delete ximble-backend-lb-01 --global -q
if [ $? -eq 0 ]
then
echo "Backend services deleted"
else
echo "Issue with Backend services deletion. Please check form console once."
fi
#####################################################################################
#####For deleting DB-Tier's#####
gcloud compute instances delete ximble-db1 --zone us-central1-a --delete-disks all -q
if [ $? -eq 0 ]
then
echo "ximble-db1 deleted"
else
echo "Issue with ximble-db1 deletion. Please check form console once."
fi
gcloud compute instances delete ximble-db2 --zone us-central1-f --delete-disks all -q
if [ $? -eq 0 ]
then
echo "ximble-db2 deleted"
else
echo "Issue with ximble-db2 deletion. Please check form console once."
fi
######################################################################################
#####For deleting Instance groups#####
gcloud compute instance-groups managed delete ximble-app --zone us-central1-a -q
if [ $? -eq 0 ]
then
echo "Instance-groups for us-central1-a deleted"
else
echo "Issue with Instance-groups for us-central1-a deletion. Please check form console once."
fi
gcloud compute instance-groups managed delete ximble-app --zone us-central1-f -q
if [ $? -eq 0 ]
then
echo "Instance-groups for us-central1-f deleted"
else
echo "Issue with Instance-groups for us-central1-f deletion. Please check form console once."
fi
########################################################################################
#####For deleting Templates#####
gcloud compute instance-templates delete ximble-app-template -q
if [ $? -eq 0 ]
then
echo "Template deleted"
else
echo "Issue with Template deletion. Please check form console once."
fi
########################################################################################
#####For deleting health check#####
gcloud compute http-health-checks delete ximble-app-health-check -q
if [ $? -eq 0 ]
then
echo "Health-check deleted"
else
echo "Issue with Health-check deletion. Please check form console once."
fi
########################################################################################
#####For Deleting network#####
gcloud compute networks subnets delete ximble-subnet --region us-central1 -q
if [ $? -eq 0 ]
then
echo "Sub-Network deleted"
else
echo "Issue with Sub-Network deletion. Please check form console once."
fi
gcloud compute firewall-rules delete allow-internal allow-ximble ximble-allow-cache ximble-allow-http ximble-allow-https -q
if [ $? -eq 0 ]
then
echo "Firewall rules deleted"
else
echo "Issue with Firewall rules deletion. Please check form console once."
fi
gcloud compute networks delete ximble -q
if [ $? -eq 0 ]
then
echo "Network deleted"
else
echo "Issue with Network deletion. Please check form console once."
fi


