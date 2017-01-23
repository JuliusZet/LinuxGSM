#!/bin/bash
# LGSM update_mta.sh function
# Author: Daniel Gibbs
# Website: https://gameservermanagers.com
# Description: Handles updating of Multi Theft Auto servers.

local commandname="UPDATE"
local commandaction="Update"
local function_selfname="$(basename $(readlink -f "${BASH_SOURCE[0]}"))"

fn_update_mta_dl(){
	fn_fetch_file "http://linux.mtasa.com/dl/${NUM_VERSION}/multitheftauto_linux_x64-${FUL_VERSION}.tar.gz" "${tmpdir}" "multitheftauto_linux_x64-${FUL_VERSION}.tar.gz"
  mkdir "${tmpdir}/multitheftauto_linux_x64-${FUL_VERSION}"
	fn_dl_extract "${tmpdir}" "multitheftauto_linux_x64-${FUL_VERSION}.tar.gz" "${tmpdir}/multitheftauto_linux_x64-${FUL_VERSION}"
	echo -e "copying to ${filesdir}...\c"
	fn_script_log "Copying to ${filesdir}"
	cp -R "${tmpdir}/multitheftauto_linux_x64-${FUL_VERSION}/"* "${filesdir}"
	local exitcode=$?
	if [ "${exitcode}" == "0" ]; then
		fn_print_ok_eol_nl
	else
		fn_print_fail_eol_nl
	fi
}

fn_update_mta_currentbuild(){
	# Gets current build info
	# Checks if current build info is available. If it fails, then a server restart will be forced to generate logs.
	if [ ! -f "${consolelogdir}/${servicename}-console.log" ]; then
		fn_print_error "Checking for update: linux.mtasa.com"
		sleep 1
		fn_print_error_nl "Checking for update: linux.mtasa.com: No logs with server version found"
		fn_script_log_error "Checking for update: linux.mtasa.com: No logs with server version found"
		sleep 1
		fn_print_info_nl "Checking for update: linux.mtasa.com: Forcing server restart"
		fn_script_log_info "Checking for update: linux.mtasa.com: Forcing server restart"
		sleep 1
		exitbypass=1
		command_stop.sh
		exitbypass=1
		command_start.sh
		sleep 1
		# Check again and exit on failure.
		if [ ! -f "${consolelogdir}/${servicename}-console.log" ]; then
			fn_print_fail_nl "Checking for update: linux.mtasa.com: Still No logs with server version found"
			fn_script_log_fatal "Checking for update: linux.mtasa.com: Still No logs with server version found"
			core_exit.sh
		fi
	fi

	# Get current build from logs
	currentbuild=$(awk -F"= Multi Theft Auto: San Andreas v" '{print $2}' "${consolelogdir}"/"${servicename}"-console.log | awk '{print $1}')
	if [ -z "${currentbuild}" ]; then
		fn_print_error_nl "Checking for update: linux.mtasa.com: Current build version not found"
		fn_script_log_error "Checking for update: linux.mtasa.com: Current build version not found"
		sleep 1
		fn_print_info_nl "Checking for update: linux.mtasa.com: Forcing server restart"
		fn_script_log_info "Checking for update: linux.mtasa.com: Forcing server restart"
		exitbypass=1
		command_stop.sh
		exitbypass=1
		command_start.sh
		currentbuild=$(awk -F"= Multi Theft Auto: San Andreas v" '{print $2}' "${consolelogdir}"/"${servicename}"-console.log | awk '{print $1}')
		if [ -z "${currentbuild}" ]; then
			fn_print_fail_nl "Checking for update: linux.mtasa.com: Current build version still not found"
			fn_script_log_fatal "Checking for update: linux.mtasa.com: Current build version still not found"
			core_exit.sh
		fi
	fi
}

fn_mta_getServerVersion()
{
		fn_fetch_file "https://raw.githubusercontent.com/multitheftauto/mtasa-blue/master/Server/version.h" "${tmpdir}" "version.h" # we need to find latest stable version here
		local MAJOR_VERSION="$(cat ${tmpdir}/version.h | grep "#define MTASA_VERSION_MAJOR" | awk '{ print $3 }' | sed 's/\r//g')"
		local MINOR_VERSION="$(cat ${tmpdir}/version.h | grep "#define MTASA_VERSION_MINOR" | awk '{ print $3 }' | sed 's/\r//g')"
		local MAINTENANCE_VERSION="$(cat ${tmpdir}/version.h | grep "#define MTASA_VERSION_MAINTENANCE" | awk '{ print $3 }' | sed 's/\r//g')"
		NUM_VERSION="${MAJOR_VERSION}${MINOR_VERSION}${MAINTENANCE_VERSION}"
		FUL_VERSION="${MAJOR_VERSION}.${MINOR_VERSION}.${MAINTENANCE_VERSION}"
		rm -f "${tmpdir}/version.h"
}

fn_update_mta_compare(){
	# Removes dots so if can compare version numbers
	currentbuilddigit=$(echo "${currentbuild}"|tr -cd '[:digit:]')

	if [ "${currentbuilddigit}" -ne "${NUM_VERSION}" ]; then
		echo -e "\n"
		echo -e "Update available:"
		sleep 1
		echo -e "	Current build: ${red}${currentbuild} ${default}"
		echo -e "	Available build: ${green}${FULL_VERSION} ${default}"
		echo -e ""
		sleep 1
		echo ""
		echo -en "Applying update.\r"
		sleep 1
		echo -en "Applying update..\r"
		sleep 1
		echo -en "Applying update...\r"
		sleep 1
		echo -en "\n"
		fn_script_log "Update available"
		fn_script_log "Current build: ${currentbuild}"
		fn_script_log "Available build: ${FULL_VERSION}"
		fn_script_log "${currentbuild} > ${FULL_VERSION}"

		unset updateonstart

		check_status.sh
		if [ "${status}" == "0" ]; then
			fn_update_mta_dl
			exitbypass=1
			command_start.sh
			exitbypass=1
			command_stop.sh
		else
			exitbypass=1
			command_stop.sh
			fn_update_mta_dl
			exitbypass=1
			command_start.sh
		fi
		alert="update"
		alert.sh
	else
		echo -e "\n"
		echo -e "No update available:"
		echo -e "	Current version: ${green}${currentbuild}${default}"
		echo -e "	Available version: ${green}${FULL_VERSION}${default}"
		echo -e ""
		fn_print_ok_nl "No update available"
		fn_script_log_info "Current build: ${currentbuild}"
		fn_script_log_info "Available build: ${FULL_VERSION}"
	fi
}


if [ "${installer}" == "1" ]; then
	fn_mta_getServerVersion
	fn_update_mta_dl
else
	# Checks for server update from linux.mtasa.com using the github repo.
	fn_print_dots "Checking for update: linux.mtasa.com"
	fn_script_log_info "Checking for update: linux.mtasa.com"
	sleep 1
	fn_update_mta_currentbuild
	fn_mta_getServerVersion
	fn_update_mta_compare
fi
