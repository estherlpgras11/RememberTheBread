#!/bin/bash
 sudo yum update -y
 sudo yum install -y docker
 sudo service docker start
 sudo docker run -d --name rtb -p 8080:8080 vermicida/rtb