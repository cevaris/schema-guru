#!/bin/bash
set -e

# Constants
bintray_package=schema-guru
bintray_artifact_prefix=schema_guru_
bintray_user=snowplowbot
bintray_repository=snowplow/snowplow-generic
scala_version=2.10
guest_repo_path=/vagrant
dist_path=dist

# Similar to Perl die
function die() {
	echo "$@" 1>&2 ; exit 1;
}

# Check if our Vagrant box is running. Expects `vagrant status` to look like:
#
# > Current machine states:
# >
# > default                   poweroff (virtualbox)
# >
# > The VM is powered off. To restart the VM, simply run `vagrant up`
#
# Parameters:
# 1. out_running (out parameter)
function is_running {
	[ "$#" -eq 1 ] || die "1 argument required, $# provided"
	local __out_running=$1

	set +e
	vagrant status | sed -n 3p | grep -q "^default\s*running (virtualbox)$"
	local retval=${?}
	set -e
	if [ ${retval} -eq "0" ] ; then
		eval ${__out_running}=1
	else
		eval ${__out_running}=0
	fi
}

# Get version, checking we are on the latest
#
# Parameters:
# 1. out_version (out parameter)
# 2. out_error (out parameter)
function get_version {
	[ "$#" -eq 2 ] || die "2 arguments required, $# provided"
	local __out_version=$1
	local __out_error=$2

	# Extract the version from SBT and save it in a .gitignored file named "VERSION"
	vagrant ssh -c "cd /vagrant && sbt -Dsbt.log.noformat=true version | tail -1 | cut -d' ' -f2 > VERSION" \
	  || die "Failed to get extract version information from package.json"
	file_version=`cat VERSION`
	tag_version=`git describe --abbrev=0 --tags`
	if [ ${file_version} != ${tag_version} ] ; then
		eval ${__out_error}="'File version ${file_version} != tag version ${tag_version}'"
	else
		eval ${__out_version}=${file_version}
	fi
}

# Go to parent-parent dir of this script
function cd_root() {
	source="${BASH_SOURCE[0]}"
	while [ -h "${source}" ] ; do source="$(readlink "${source}")"; done
	dir="$( cd -P "$( dirname "${source}" )/.." && pwd )"
	cd ${dir}
}

# Assemble our fat jars
function assemble_fatjar() {
	echo "================================================"
	echo "ASSEMBLING FATJAR"
	echo "------------------------------------------------"
	vagrant ssh -c "cd ${guest_repo_path} && sbt assembly"
}

# Create our version in BinTray. Does nothing
# if the version already exists
#
# Parameters:
# 1. package_version
# 2. out_error (out parameter)
function create_bintray_package() {
    [ "$#" -eq 2 ] || die "2 arguments required, $# provided"
    local __package_version=$1
    local __out_error=$2

	echo "========================================"
	echo "CREATING BINTRAY VERSION ${__package_version}*"
	echo "* if it doesn't already exist"
	echo "----------------------------------------"

	http_status=`echo '{"name":"'${__package_version}'","desc":"Release of '${bintray_package}'"}' | curl -d @- \
		"https://api.bintray.com/packages/${bintray_repository}/${bintray_package}/versions" \
		--write-out "%{http_code}\n" --silent --output /dev/null \
		--header "Content-Type:application/json" \
		-u${bintray_user}:${bintray_api_key}`

	http_status_class=${http_status:0:1}
	ok_classes=("2" "3")

	if [ ${http_status} == "409" ] ; then
		echo "... version ${__package_version} already exists, skipping."
	elif [[ ! ${ok_classes[*]} =~ ${http_status_class} ]] ; then
		eval ${__out_error}="'BinTray API response ${http_status} is not 409 (package already exists) nor in 2xx or 3xx range'"
	fi
}

# Zips all of our applications
#
# Parameters:
# 1. artifact_version
# 2. out_artifact_name (out parameter)
# 3. out_artifact_[atj] (out parameter)
function build_artifact() {
    [ "$#" -eq 3 ] || die "3 arguments required, $# provided"
    local __artifact_version=$1
    local __out_artifact_name=$2
    local __out_artifact_path=$3

    artifact_root="${bintray_artifact_prefix}${__artifact_version}"
    artifact_name=`echo ${artifact_root}.zip|tr '-' '_'`
	echo "==========================================="
	echo "BUILDING ARTIFACT ${artifact_name}"
	echo "-------------------------------------------"

	artifact_folder=./${dist_path}
	mkdir -p ${artifact_folder}

	fatjar_file="huskimo-${__artifact_version}"
	fatjar_path="./target/scala-${scala_version}/${fatjar_file}"
	[ -f "${fatjar_path}" ] || die "Cannot find required fatjar: ${fatjar_path}. Did you forget to update fatjar versions?"
	cp ${fatjar_path} ${artifact_folder}

	artifact_path=./${dist_path}/${artifact_name}
	zip -j ${artifact_path} ${artifact_folder}/${fatjar_file}
	eval ${__out_artifact_name}=${artifact_name}
	eval ${__out_artifact_path}=${artifact_path}
}

# Uploads our artifact to BinTray
#
# Parameters:
# 1. artifact_name
# 2. artifact_path
# 3. out_error (out parameter)
function upload_artifact_to_bintray() {
    [ "$#" -eq 3 ] || die "3 arguments required, $# provided"
    local __artifact_name=$1
    local __artifact_path=$2
    local __out_error=$3

	echo "==============================="
	echo "UPLOADING ARTIFACT TO BINTRAY*"
	echo "* 2-3 minutes"
	echo "-------------------------------"

	http_status=`curl -T ${__artifact_path} \
		"https://api.bintray.com/content/${bintray_repository}/${bintray_package}/${version}/${__artifact_name}?publish=1&override=1" \
		-H "Transfer-Encoding: chunked" \
		--write-out "%{http_code}\n" --silent --output /dev/null \
		-u${bintray_user}:${bintray_api_key}`

	http_status_class=${http_status:0:1}
	ok_classes=("2" "3")

	if [[ ! ${ok_classes[*]} =~ ${http_status_class} ]] ; then
		eval ${__out_error}="'BinTray API response ${http_status} is not in 2xx or 3xx range'"
	fi
}


cd_root

# Precondition for running
running=0 && is_running "running"
[ ${running} -eq 1 ] || die "Vagrant guest must be running to push"

# Precondition
version="" && error="" && get_version "version" "error"
[ "${error}" ] && die "Versions don't match: ${error}. Are you trying to publish an old version, or maybe on the wrong branch?"

# Can't pass args thru vagrant push so have to prompt
read -e -p "Please enter API key for Bintray user ${bintray_user}: " bintray_api_key

assemble_fatjar

create_bintray_package "${version}" "error"
[ "${error}" ] && die "Error creating package: ${error}"

artifact_name="" && artifact_path="" && build_artifact "${version}" "artifact_name" "artifact_path"

upload_artifact_to_bintray "${artifact_name}" "${artifact_path}" "error"
[ "${error}" ] && die "Error uploading package: ${error}"
