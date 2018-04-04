#!/bin/bash
##########################################################
#
# This Script executes Procedures to install Exercises
# of the T-Systems GDU SI DI Training for OpenShift
#
# written by Thomas Wetzler
# April 2018
#
# Call the script OpenShiftTraining.sh -f <function> -t <logintoken>
#
# Required Input Parameter
#    <function> 
#       createproject	- creates the ex-insults-app
#	delete		- deletes all elements out our the ex-insults-app project
#	installtool	- installes the oc tools to local mashine
#	installos	- installes a local OpenShift Origin Instance (tbd)
#	installjmeter	- installes JMeter
#	exericse1	- deletes all elements and installes into AppAgile Elements produced during Exercise I
#	exercise2	- deletes all elements and installes into AppAgile Elements produced during Exercise II
#
# Prerequisite
#    Installed CentOS 7 Mashine
#
##########################################################
# Swich Language to English
export LC_ALL=C
# Start Time for Statistics
script_start_time=$(date +"%s")

# Static Parameter for AppAgile
URL="https://master-azp18.appagile.de:8443"
PROJECT="ex-insults-app"


#
# Main Procedure
main() 
{
	get_parameter $@
	prepare_os
	testroot
	testinternet
	case $FUNCTION in 
		delete)
			delete_all
		;;		
		installtool)
			install_openshifttools
		;;		
		installos)
			#install_docker
			#install_openshift
		;;		
		installjmeter)
			install_jmeter
		;;		
		exercises1)
			login_OpenShift
			exerciseI
		;;		
		exercises2)
			login_OpenShift
			exerciseII
		;;		
	esac
	endofinstalltion
}

#
# Scan Commandshell Parameter
get_parameter()
{
        # Test if a parameter is given
        if [[ $# -ge 5 ]] ; then
                # more than two parameter
                echo "$0 - ERROR: There are more than needed Parameter."
		exit 
        fi
        if [[ $# -le 3 ]] ; then
                # Parameter missing
                echo "$0 - ERROR: Parameter missing."
        else
                # Parameter given
                while [[ $# -gt 0 ]] ; do
			key="$1"
			case $key in 
				-t|--token)
					TOKEN="$2"
					shift # past argument
					shift # past value
					;;
				-f|--function)
					FUNCTION="$2"
					shift # past argument
					shift # past value
					;;
			esac
		done	
		# restore positional paramenters
		set -- "${POSITIONAL[@]}"
		echo "You selected $FUNCTION"
        fi
}

#
# Prepare Operation System
prepare_os()
{
	# Enable ssh Tunneling Forwarding
	sudo sed 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config > /tmp/sshd_config
	sudo mv /tmp/sshd_config /etc/ssh/sshd_config
	sudo chown root.root /etc/ssh/sshd_config
	# ssh -L 51443:localhost:8443 ca-openshift
	# Update Firewall
	sudo firewall-cmd --add-port=8443/tcp
	sudo firewall-cmd --add-port=8443/tcp --permanent
	# Install
	sudo yum -y install git wget
}

#
# Install Docker
install_docker()
{
	sudo yum -y install docker
	sudo sed 's/--selinux-enabled /--selinux-enabled=false /' /etc/sysconfig/docker > ~/docker.conf
	sudo mv ~/docker.conf /etc/sysconfig/docker
	sudo chown root.root /etc/sysconfig/docker
	sudo systemctl enable docker
	sudo systemctl start docker
	sudo systemctl status docker.service
	# Allow selfsigned Zertificate for Registry within OpenShift 
	echo '{"insecure-registries": ["172.30.0.0/16"] }' > ~/daemon.json
	sudo mv ~/daemon.json /etc/docker/daemon.json
	sudo systemctl daemon-reload
	sudo systemctl restart docker
}

#
# Install OpenShift Tools
install_openshifttools()
{
	# Download & Install oc Tool
	cd /tmp
	wget -O /tmp/openshift-origin-client-tools-v3.7.2-282e43f-linux-64bit.tar.gz https://github.com/openshift/origin/releases/download/v3.7.2/openshift-origin-client-tools-v3.7.2-282e43f-linux-64bit.tar.gz
	gzip -d /tmp/openshift-origin-client-tools-v3.7.2-282e43f-linux-64bit.tar.gz
	tar -xvf /tmp/openshift-origin-client-tools-v3.7.2-282e43f-linux-64bit.tar
	sudo cp /tmp/openshift-origin-client-tools-v3.7.2-282e43f-linux-64bit/oc  /usr/bin/
	rm -rf /tmp/openshift-origin-client-tools-v3.7.2-282e43f-linux-64bit*
	# Enable autocompleation
	cd ~
	oc completion bash > ~/.os_completion.sh
	echo "source ${PWD}/.oc_completion.sh" >> ~/.bashrc 
}


#
# Install JMeter
install_jmeter()
{
	echo "Install JMeter"	
	cd /tmp
	wget -O /tmp/apache-jmeter-4.0.tgz http://mirror.23media.de/apache/jmeter/binaries/apache-jmeter-4.0.tgz
	gzip -d /tmp/apache-jmeter-4.0.tgz
	tar -xvf /tmp/apache-jmeter-4.0.tar
	sudo apt-get install default-jre
	var="JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64/\""
	if ! grep -Fxq "$var" /etc/environment ; then
		echo "$var" | sudo tee --append /etc/environment > /dev/null
		source /etc/environment
	fi
	echo "Start JMeter with X11 Environment"
	echo "..."
}


#
# Login to OpenShift
login_OpenShift()
{
	echo "Loging to OpenShift"
	oc login $URL --token=$TOKEN
}

#
# Test, if Login to right project has been done
check_project()
{
	# Check, if Login to right project has been done
	project=($(oc project | awk 'BEGIN{FS=" |\""} { printf "%s\n", $5}' ))
        if [ ! $project = $PROJECT ]; then
        	oc project $PROJECT
		# Check, if assigment has been successfull
		project=($(oc project | awk 'BEGIN{FS=" |\""} { printf "%s\n", $5}' ))
        	if [ ! $project = $PROJECT ]; then
			echo "Assigment to Project hasn't been successfull"
			exit 
		fi	
        fi
}

#
# Delete all ressources within Project
delete_all()
{
	# Check, if logon to project has been done
	check_project
	# Delete all 
	oc delete all --all
}

#
# Create OpenShift Project Elizabethan Insult Application
create_ocproject()
{
        # Check, if project exists
        check=false
        projects=($(oc get --output=json projects | awk 'BEGIN{FS="\"|:|,"} /\"name\":/ { printf "%s\n", $5}' ))
        for i in "${projects[@]}"
        do :
                if [ $i = $PROJECT ]; then
                        check=true
                fi
        done
        if ! $check  ; then
                # Create project
                oc new-project $PROJECT --display-name="Elizabethan Insult Application"
        fi
}

#
# Exercsise I
exerciseI()
{
	# Check, if logon to project has been done
	echo "Login Project"
	check_project
	# Generate Pod out of Image & Git Repository
	echo "Download Image and Clone Code"
	oc new-app openshift/wildfly-100-centos7:latest~https://github.com/thomaswetzler/insults-app.git --name='insults'
	# Generate Route to Service
	echo "Generate Route"
	oc expose service insults
	# Show routes
	echo "Show Routes"
	oc get routes
}


#
# Exercise II
exerciseII()
{
	# Check, if logon to project has been done
	check_project
	echo
}

#
#

# Test Internet connection
#
testinternet() 
{
        wget -q --spider http://google.com
        if [ $? -ne 0 ]; then
                echo "Ausführung nur mit bestehender Internetverbindung möglich!"
                exit 1;
        else
                echo "Es besteht eine Internetverbindung..."
                echo
        fi
}

# Test If Root-User
#
testroot() 
{

        if [ $(whoami) = 'root' ]; then
                echo "Ausführung von $0 sollte nicht unter root geschehen"
                exit 1;
        fi
}

#
# Install local OpenShift Origin
install_openshift()
{
	sudo oc cluster up
}

#
# Statistics
endofinstalltion() 
{
	echo ' '
	echo '+---------------------------------------------------------------+'
	echo '|  END OF INSTALLTION                                           |'
	echo '+---------------------------------------------------------------+'
	script_end_time=$(date +"%s")
	script_elapsed_times=$(($script_end_time-$script_start_time))
	echo "$(($script_elapsed_times / 60)) minutes and $(($script_elapsed_times % 60)) seconds elapsed for Script Execution."
	echo
}

#####################################################################
#
# INIT - Start Installtion with main routine
#
#####################################################################
main $@


#####################################################################
#
# END OF FILE
#
#####################################################################
