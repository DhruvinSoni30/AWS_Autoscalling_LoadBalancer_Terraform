#!/bin/bash

sudo apt update -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" -y
sudo apt update -y
sudo apt install docker-ce -y
sudo usermod -aG docker ${USER}
su - ${USER}
sudo usermod -aG docker username
docker pull dhruvin30/dhsoniweb:v1
docker run -d -p 80:80 dhruvin30/dhsoniweb:v1