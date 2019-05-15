# Data Science Maker - Hants 

## Installation

Amazon EC2.

### Amazon EC2

Amazon EC2 is the preferred and only environment for this material. Installation takes just a few moments using Amazon EC2. 

First you will need to install the Amazon CLI via:

```
pip install awscli
```

Now you must authenticate into the AWS CLI via:

```
aws configure
```

Once you've provided it your AWS credentials, run the following command to bring up a machine pre-configured with a complete environment and source code:

```
chmod -x ec2_autostarter_create.sh
chmod 777 ec2_autostarter_create.sh 
./ec2_autostarter_create.sh
```

#### How it Works

The script [ec2_autostarter_create.sh](ec2_autostarter_create.sh) creates and boots a single t2.micro EC2 instance. During the bash script process, you are able to either create new security groups/.PEM key files or select existing ones, and set the EBS storage amount and set a tag-name for the newly created instance.  The script's security setting only opens port 22 during the creation. This can be modified later on if required. 


#### Next Steps

Once the script has finished, log into your root / AWS console and confirm that the instance has been created. The two additional scripts located in this folder (ec2_bootstrap_part1 and ec2_bootstrap_part2) are then utilized to install package updates and specific software to the ec2 instance that are commonly used (python-pyenv, superset, mysql, airflow)


