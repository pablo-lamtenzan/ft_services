#!/usr/bin/env bash

# globals
CONTAINERS=("nginx" "influxdb" "grafana" "mysql" "phpmyadmin" "wordpress" "telegraf" "ftps")
ADDONS=("metrics-server" "dashboard")
NAME=services
DRIVER=docker
CONFIGMAP=
KEYDIR=keys
KEYHOST="${NAME}"

start_minikube()
{
    echo -e "\033[1;32m+>\033[0;33m Starting minikube ..."
    minikube -p "${NAME}" start "--driver=${DRIVER}"
}

enable_addons()
{
    for ADDON in ${ADDONS[@]}
    do
        minikube -p "${NAME}" addons enable "${ADDON}"
        echo -e "\033[1;32m+>\033[0;33m Addons: ${ADDON} has been enabled ..."
    done
}

set_up_MetalLB()
{
    echo -e "\033[1;32m+>\033[0;33m Seting up Load Balancer:MetalLB ..."
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
}

# to study
set_up_Namespaces()
{
    echo -e "\033[1;32m+>\033[0;33m Seting up Namespaces ..."
    kubectl apply -f srcs/namespaces.yaml
}

get_configmap()
{
    # have to understand how to calc the range
    # split ip address and check for last and set 1/32 or 128/32
    LB_RANGE=$(minikube -p "${NAME}" ip)

    CONFIGMAP=$(cat <<- EOF
		address-pools:
		- name: default
		  protocol: layer2
		  addresses:
		  - ${LB_RANGE}
	EOF
	)
}

update_configmap()
{
    echo -e "\033[1;32m+>\033[0;33m Updating configmap ..."
    kubectl --namespace metallb-system delete configmap config || :
	kubectl --namespace metallb-system create configmap config --from-literal="config=${CONFIGMAP}"
}

# to study
set_up_Networking()
{
    get_configmap
    echo -e "CONFIGMAP:${CONFIGMAP}"
    update_configmap
}

build_container()
{
    echo -e "\033[1;32m+>\033[0;33m Building ${1} image ... "
    docker build -qt "ft_services/${1}" "srcs/containers/${1}"
}

build_containers()
{
    echo -e "\033[1;32m+>\033[0;33m Building containers ..."
    eval $(minikube -p "${NAME}" docker-env)
    for CONTAINER in ${CONTAINERS[@]}
    do
        build_container "${CONTAINER}"
    done
}

update_TLS_secret()
{
    kubectl delete secret default-tls || :
	kubectl create secret tls default-tls --key "${KEYDIR}/${KEYHOST}.key" --cert "${KEYDIR}/${KEYHOST}.csr"
	kubectl delete secret -n monitoring default-tls || :
	kubectl create secret -n monitoring tls default-tls --key "${KEYDIR}/${KEYHOST}.key" --cert "${KEYDIR}/${KEYHOST}.csr"
    echo -e "\033[1;32m+>\033[0;33m TLS secret has been updated!"
}

update_MetalLB_secret()
{
    kubectl delete secret -n metallb-system memberlist || :
	kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
    echo -e "\033[1;32m+>\033[0;33m MetalLB secret has been updated!"
}

update_Grafana_secret()
{
    kubectl delete secret -n monitoring grafana-secretkey || :
	kubectl create secret generic -n monitoring grafana-secretkey --from-literal=secretkey="$(openssl rand -base64 20)"
    echo -e "\033[1;32m+>\033[0;33m Grafana secret has been updated!"
}

gen_certs()
{
    # Generate TLS keys
	mkdir -p "${KEYDIR}"

	openssl req -x509 -nodes -days 365\
		-newkey rsa:2048\
		-keyout "${KEYDIR}/${KEYHOST}.key"\
		-out "${KEYDIR}/${KEYHOST}.csr"\
		-subj "/CN=*.${KEYHOST}/O=${KEYHOST}"
}

# to study
build_certs()
{
    if [ ! -d "${KEYDIR}" ]; then
        gen_certs
    fi
    echo -e "\033[1;32m+>\033[0;33m Building certs ... "
    update_TLS_secret
    update_MetalLB_secret
    update_Grafana_secret
}

apply()
{
    kubectl apply -k srcs
    echo -e "\033[1;32m+>\033[0;33m Services are up!"
}

setup_all()
{
    start_minikube
    enable_addons
    set_up_MetalLB
    set_up_Namespaces
    set_up_Networking
    build_containers
    build_certs
    apply
}

############################## TRIVIAL FCTS ##################################

stop_minikube()
{
    minikube -p "${NAME}" stop
}

delete_minikube()
{
    minikube -p "${NAME}" delete
    rm -rf ${KEYDIR}
}

open_dashboard()
{
    minikube -p "${NAME}" dashboard --url
}

help()
{
	echo "Usage: ${0} <option>
	
	Commands:
		--setup			-> Setups and starts a new cluster.
		--start			-> Start existing cluster and apply changes.
		--stop			-> Stop the current running cluster.
		--delete		-> Delete the current cluster.
		--dashboard		-> Enable the dashboard.
		--help			-> Print all options.
		
	If no option as argumnt -setup will be set by default"
}

clear

#todo

#update configmap server not found "config"
#build cerst "default-tls" not found
#build cerst "memberlist" not found
#build cerst "grafana-secretkey" not found
#check for kustomization error
#study all

case "${1}" in
	"--setup" | ""	)		setup_all;;
	"--start"		)		start_minikube;;
	"--stop"		)		stop_minikube;;
	"--restart"		)		stop_minikube; start_minikube;;
	"--delete"		)		delete_minikube;;
	"--dashboard"	)		open_dashboard;;
	*				)		help;;
esac
