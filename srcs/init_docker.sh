
# set the user variable in local env
[ -z "${USER}" ] && export USER=`whoami`

# set docker destination
docker_destination="/goinfre/$USER/docker"

# style points
blue=$'\033[0;34m'
cyan=$'\033[1;96m'
reset=$'\033[0;39m'

# unistall docker and it derivatives if they have been unstalled with brew
brew uninstall -f docker docker-compose docker-machine ;:

# check if docker has been staled with MSC (open NSC if false)
if [ ! -d "/Applications/Docker.app" ] && [ ! -d "~/Applications/Docker.app" ]; then
	echo -e "${blue}Please install ${cyan}Docker for Mac ${blue}from the MSC (Managed Software Center)${reset}"
	open -a "Managed Software Center"
	read -n1 -p "${blue}Press RETURN when you have successfully installed ${cyan}Docker for Mac${blue}...${reset}"
	echo ""
fi

function rm_and_link() {
	rm -rf ~/Library/Containers/com.docker.docker ~/.docker
	mkdir -p $docker_destination/{com.docker.docker,.docker}
	ln -sf $docker_destination/com.docker.docker ~/Library/Containers/com.docker.docker
	ln -sf $docker_destination/.docker ~/.docker
}

# kill docker if it's up
pkill Docker

# creating the needed files then link them
if [ -d $docker_destination ]; then
	read -n1 -p "${blue}Folder ${cyan}$docker_destination${blue} already exists, do you want to reset it? [y/${cyan}N${blue}]${reset} " input
	echo ""
	if [ -n "$input" ] && [ "$input" = "y" ]; then
		rm_and_link
	fi
else
	rm_and_link
fi

# starting docker
open -g -a Docker
echo -e "${cyan}Docker${blue} is now starting! Please report any bug to: ${cyan}plamtenz--${reset}"