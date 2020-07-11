#!  bin/bash

# $1 -> server ip
# $2 -> path 
set_ip()
{
    sed -i.bak 's/http:\/\/IP/http:\/\/'"$1"'/g' $2
    sleep 1
}

# $1 -> container name
build_container()
{
    echo -e "\033[1;32m+>\033[0;33m Building $1 image ... "
    docker build -t services/$1 srcs/containers/$1/ &> /dev/null
    sleep 1
}

# $1 -> service name
up_service()
{
    echo -e "\033[1;32m+>\033[0;33m $1 service is up... "
    kubectl apply -f srcs/yaml/$1.yaml &> /dev/null
    sleep 1
}

clear


# installing brew and docker for macOS

# Brew istalled in host ?
# no -> install it
# yes -> check for update
#which -s brew
#if [[ $? != 0 ]] ; then
#	echo -e "\033[1;31m+>\033[0;33m Intalling brew... "
#	rm -rf $HOME/.brew && git clone --depth=1 https://github.com/Homebrew/brew $HOME/.brew && export PATH=$HOME/.brew/bin:$PATH && brew update && echo "export PATH=$HOME/.brew/bin:$PATH" >> ~/.zshrc &> /dev/null
#else
#	echo -e "\033[1;32m+>\033[0;33m Updating brew... "
#	brew update &> /dev/null
#fi

#echo "N" | bash srcs/init_docker.sh
#echo -e "\033[1;33m+>\033[0;33m Waiting for docker ... "
#until docker &> /dev/null
#do
#	&> /dev/null
#done

# liking to goinfre (or any folder)
# export MINIKUBE_HOME=/goinfre/$USER/
# rm -rf /goinfre/$USER/.minikube

# installing minikube MacOS

# minikube in host ?
# n -> install it
# y -> check for update
#if minikube &> /dev/null
#then
#	echo -e "\033[1;33m+>\033[0;33m checking Minikube for upgrade ... "
#	if brew upgrade minikube &> /dev/null
#	then
#		echo -e "\033[1;32m+>\033[0;33m Minikube updated "
#	else
#		echo -e "\033[1;31m+>\033[0;33m Error: minikube can't be uptated"
#		exit 1
#	fi
#else
#	echo -e "\033[1;31m+>\033[0;33m Installing minikube ..."
#	if brew install minikube &> /dev/null
#	then
#		echo -e "\033[1;32m+>\033[0;33m Minikube installed"
#	else
#		echo -e "\033[1;31m+>\033[0;33m Error: minikube can't be installed"
#	fi
#fi

echo -e "\033[1;32m+>\033[0;33m Starting minikube (could take a few minutes)"
minikube config set vm-driver virtualbox
minikube delete
minikube start --bootstrapper=kubeadm --extra-config=apiserver.service-node-port-range=1-30000
#minikube start --vm-driver=virtualbox

server_ip=`minikube ip`
sed_list="srcs/containers/mysql/wp.sql srcs/containers/wordpress/wp-config.php srcs/yaml/telegraf.yaml"

# seting the IP on configs
for path in $sed_list
do
	set_ip $server_ip $path
done

echo -e "\033[1;32m+>\033[0;33m Updating grafana db ..."
echo "UPDATE data_source SET url = 'http://$server_ip:8086'" | sqlite3 srcs/containers/grafana/grafana.db

echo -e "\033[1;32m+>\033[0;33m Opening ports ..."
minikube ssh "sudo -u root awk 'NR==14{print \"    - --service-node-port-range=1-35000\"}7' /etc/kubernetes/manifests/kube-apiserver.yaml >> tmp && sudo -u root rm /etc/kubernetes/manifests/kube-apiserver.yaml && sudo -u root mv tmp /etc/kubernetes/manifests/kube-apiserver.yaml"

echo -e "\033[1;32m+>\033[0;33m Linking docker local image to minikube ..."
eval $(minikube docker-env)

sed -i.bak 's/MINIKUBE_IP/'"$server_ip"'/g' srcs/containers/ftps/setup.sh

# building a container for each service
names="nginx influxdb grafana mysql phpmyadmin wordpress telegraf ftps"

for name in $names
do
	build_container $name
	up_service $name
done
minikube addons enable ingress
echo -e "\033[1;33m+>\033[0;33m IP : $server_ip "
sleep 1

# config defualt config files uptading the ip
sed -i.bak 's/http:\/\/'"$server_ip"'/http:\/\/IP/g' srcs/containers/mysql/wp.sql
sleep 1
sed -i.bak 's/http:\/\/'"$server_ip"'/http:\/\/IP/g' srcs/containers/wordpress/wp-config.php

sleep 1
sed -i.bak 's/http:\/\/'"$server_ip"'/http:\/\/IP/g' srcs/yaml/telegraf.yaml
sleep 1
sed -i.bak 's/'"$server_ip"'/MINIKUBE_IP/g' srcs/containers/ftps/setup.sh
sleep 1

echo -e "\033[1;32m+>\033[0;33m Waiting for the site ..."
until $(curl --output /dev/null --silent --head --fail http://$server_ip/); do
	echo -n "."
	sleep 2
done;

echo -e " Opening website ... "
open http://$server_ip

### Dashboard
# minikube dashboard

###
# ssh admin@$(minikube ip) -p 1234

### Crash Container
# kubectl exec -it $(kubectl get pods | grep mysql | cut -d" " -f1) -- /bin/sh -c "ps"  
# kubectl exec -it $(kubectl get pods | grep mysql | cut -d" " -f1) -- /bin/sh -c "kill number" 