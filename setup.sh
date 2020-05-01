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

# Brew istalled in host ?
# no -> install it
# yes -> check for update
which -s brew
if [[ $? != 0 ]] ; then
	echo -e "\033[1;31m+>\033[0;33m Intalling brew... "
	rm -rf $HOME/.brew && git clone --depth=1 https://github.com/Homebrew/brew $HOME/.brew && export PATH=$HOME/.brew/bin:$PATH && brew update && echo "export PATH=$HOME/.brew/bin:$PATH" >> ~/.zshrc &> /dev/null
else
	echo -e "\033[1;32m+>\033[0;33m Updating brew... "
	brew update &> /dev/null
fi

echo "N" | bash srcs/init_docker.sh
echo -e "\033[1;33m+>\033[0;33m Waiting for docker ... "
until docker &> /dev/null
do
	&> /dev/null
done

# liking to goinfre (or any folder)
export MINIKUBE_HOME=/goinfre/$USER/
rm -rf /goinfre/$USER/.minikube

# minikube in host ?
# n -> install it
# y -> check for update
if minikube &> /dev/null
then
	echo -e "\033[1;33m+>\033[0;33m checking Minikube for upgrade ... "
	if brew upgrade minikube &> /dev/null
	then
		echo -e "\033[1;32m+>\033[0;33m Minikube updated "
	else
		echo -e "\033[1;31m+>\033[0;33m Error: minikube can't be uptated"
		exit 1
	fi
else
	echo -e "\033[1;31m+>\033[0;33m Installing minikube ..."
	if brew install minikube &> /dev/null
	then
		echo -e "\033[1;32m+>\033[0;33m Minikube installed"
	else
		echo -e "\033[1;31m+>\033[0;33m Error: minikube can't be installed"
	fi
fi

echo -e "\033[1;32m+>\033[0;33m Starting minikube (could take a few minutes)"
minikube start --vm-driver=virtualbox

server_ip=`minikube ip`
sed_list="srcs/containers/mysql/wp.sql srcs/containers/wordpress/wp-config.php srcs/yaml/telegraf.yaml"
