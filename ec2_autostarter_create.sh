#!/usr/bin/env bash

LOG_FILE="ec2.sh.log"
echo "Logging to \"$LOG_FILE\" ..." | tee -a $LOG_FILE
echo "Logging operations to '$LOG_FILE' in this folder (folder you are running this script from) ..." 
echo "Please remember, before this script can properly function, you must have AWS CLI installed on the computer"

################################################################################

read -p 'Do you want to create a new security group and pem key file? YES or NO: ' userresponse1


if [ "$userresponse1" = "YES" ]; then

  #The below portion of this script is if the response is - YES - process for creating a new security 
  #group and .PEM file to be utilized to connect to EC2 instance 
  echo 'Creating a Secuirty Group with Port Open 22 for SSH'
  read -p 'Please provide a name for the new security group: ' varsecurityname
  echo 'Received, your security group name will be ' $varsecurityname;
  aws ec2 create-security-group --group-name $varsecurityname --description "Security Group for EC2 instances to allow port 22"
  aws ec2 authorize-security-group-ingress --group-name $varsecurityname --protocol tcp --port 22 --cidr 0.0.0.0/0
  aws ec2 describe-security-groups --group-names $varsecurityname
  echo 'Completed';
  echo 'Create a new security key the EC2 instance about to be created'
  read -p 'Please provide a name for the new key: ' awskeypair
  aws ec2 create-key-pair --key-name $awskeypair --query 'KeyMaterial' --output text > $awskeypair.pem
  echo 'Confirm the newly created .pem file is located in the folder in which this script is running'
  echo 'Creating a EC2 t2.micro instance with the security group created above';
  read -p 'Please provide a tag name for the new instance: ' instancetagname
  read -p 'Please provide a EBS volume amount, e.g., = 8 (recommend 8gb for scratch instance): ' ebsvolumeamount
  
  aws ec2 run-instances \
      --image-id ami-005bdb005fb00e791 \
      --security-groups $varsecurityname \
      --key-name $awskeypair \
      --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$instancetagname'}]' \
      --instance-type t2.micro \
      --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":true,"VolumeSize":'$ebsvolumeamount'}}' \
      --count 1 \
      #--user-data file://ec2_bootstrap.sh \
  
  echo 'Completed - Please Check AWS to confirm';
  

elif [ "$userresponse1" = "NO" ]; then 
  #The below portion of this script is if the response is - NO - e.g., we just collect from the user
  #the names of the existing security group and .pem that will be utilized for the new EC2 instance 
  echo '....lets do something different'
  echo '....Utilizing existing security group and PEM key'
  read -p 'Please provide the existing name of the security group: ' varsecurityname
  read -p 'Please provide the existing ame of the .PEM key to be utilized: ' awskeypair
  echo 'Creating a EC2 t2.micro instance with the security group provided above';
  read -p 'Please provide a tag name for the new instance: ' instancetagname
  read -p 'Please provide a EBS volume amount, e.g., = 8 (recommend 8gb for scratch instance): ' ebsvolumeamount

  aws ec2 run-instances \
      --image-id ami-005bdb005fb00e791 \
      --security-groups $varsecurityname \
      --key-name $awskeypair \
      --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$instancetagname'}]' \
      --instance-type t2.micro \
      --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":true,"VolumeSize":'$ebsvolumeamount'}}' \
      --count 1 \
 
  echo 'Completed - Please Check AWS to confirm';

else 
  echo 'No appropriate response detected - ......terminating'

fi
  