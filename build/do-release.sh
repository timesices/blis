#!/bin/sh
#
#  BLIS
#  An object-based framework for developing high-performance BLAS-like
#  libraries.
#
#  Copyright (C) 2014, The University of Texas at Austin
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are
#  met:
#   - Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   - Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   - Neither the name(s) of the copyright holder(s) nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#

#
# bump-version.sh
#
# Field G. Van Zee
#


print_usage()
{
	echo <<- EOF

	$script_name

	 Field G. Van Zee

	 Performs a series of actions needed when creating a new release
	 candidate branch for BLIS:
	   1. Overwrite the version file with the version string passed
	      into this script (<new_vers>).
	   2. Commit the updated version file.
	   3. Update the CHANGELOG file.
	   4. Commit the updated CHANGELOG file.
	   5. Create a new branch (named 'r<new_vers>') which refers to
	      the commit created in (4).
	   6. Tag the commit created in (4) with a tage '<new_vers>'.

	 Usage:
	   ${script_name} [options] new_vers"

	 Arguments:

	   new_vers     The new version string.

	 Options:

	   -b           bare update
	                  Update the version and CHANGELOG files but do not create
	                  a release branch or tag.
	   -d           dry-run
	                  Go through all the motions, but don't actually make any
	                  changes to files or perform any git commits. Note that
	                  this will result in the commits for (2) and (4) above
	                  being equal to the initial commit in the script output.
	   -f VERSFILE  version file name
	                  Update VERSFILE with new version string instead of default
	                  'version' file.
	EOF

	exit 1
}


main()
{
	# -- BEGIN GLOBAL VARIABLE DECLARATIONS --

	# The name of the script, stripped of any preceeding path.
	script_name=${0##*/}

	# The name of the config.mk file.
	configmk_file='config.mk'

	# The name of the CHANGELOG file.
	changelog_file='CHANGELOG'

	# The name and location of the default version file.
	version_file_def='build/version'

	# The name and location of the specified version file.
	version_file=''

	# Strings used during version query.
	git_commit_str=''
	new_version_str=''
	new_rc_str=''

	# Master branch name.
	master_br=master

	# The script name to use instead of the $0 when outputting messages.
	output_name=''

	# The git directory.
	gitdir='.git'

	# Whether we are performing a dry run or not.
	dry_run_flag=""

	# Whether we are doing a bare update or not.
	bare_flag=""

	# -- END GLOBAL VARIABLE DECLARATIONS --


	# Process our command line options.
	while getopts ":dhbf:" opt; do
		case $opt in
			d  ) dry_run_flag="1" ;;
			b  ) bare_flag="1" ;;
			f  ) version_file=$OPTARG ;;
			h  ) print_usage ;;
			\? ) print_usage
		esac
	done
	shift $(($OPTIND - 1))


	# If a version file name was not given, set version_file to the default
	# value.
	if [ -n "${version_file}" ]; then

		echo "${script_name}: version file specified: '${version_file}'."
	else

		echo "${script_name}: no version file specified; defaulting to '${version_file_def}'."
		version_file="${version_file_def}"
	fi


	# Check the number of arguments after command line option processing.
	if [ $# = "1" ]; then

		new_version_str=$1
		new_rc_str="r${new_version_str}"

		echo "${script_name}: new version string: '${new_version_str}'."
		if [ -z "${bare_flag}" ]; then
			echo "${script_name}: preparing to create release (candidate) branch '${new_rc_str}'."
		fi

	else
		print_usage
	fi


	# Check if the .git dir exists; if it does not, we do nothing.
	if [ -d "${gitdir}" ]; then

		echo "${script_name}: found '${gitdir}' directory; assuming git clone."

		git_commit_str=$(git describe --always)
		echo "${script_name}: initial commit: ${git_commit_str}."

		echo "${script_name}: updating version file '${version_file}'."
		if [ -z "$dry_run_flag" ]; then
			echo "${new_version_str}" > ${version_file}
		fi

		echo "${script_name}: executing: git commit -m \"Version file update (${new_version_str})\" ${version_file}."
		if [ -z "$dry_run_flag" ]; then
			git commit -m "Version file update (${new_version_str})" ${version_file}
		fi

		git_commit_str=$(git describe --always)
		echo "${script_name}: new commit containing version file update: ${git_commit_str}."

		echo "${script_name}: updating '${changelog_file}'."
		if [ -z "$dry_run_flag" ]; then
			git log --no-decorate > ${changelog_file}
		fi

		echo "${script_name}: executing: git commit -m \"CHANGELOG update (${new_version_str})\" ${changelog_file}."
		if [ -z "$dry_run_flag" ]; then
			git commit -m "CHANGELOG update (${new_version_str})" ${changelog_file}
		fi

		git_commit_str=$(git describe --always)
		echo "${script_name}: new commit containing CHANGELOG update: ${git_commit_str}."

		if [ -z "${bare_flag}" ]; then

			echo "${script_name}: Creating branch ${new_rc_str}."
			if [ -z "$dry_run_flag" ]; then
				git branch "${new_rc_str}"
			fi

			echo "${script_name}: Tagging branch ${new_rc_str} with tag ${new_version_str}."
			if [ -z "$dry_run_flag" ]; then
				git tag "${new_version_str}" "${new_rc_str}"
			fi

			echo "${script_name}: "
			echo "${script_name}: FINAL STEPS: Check the output of 'git log'. If everything"
			echo "${script_name}: looks okay, push the new branch manually:"
			echo "${script_name}: "
			echo "${script_name}:   git push"
			echo "${script_name}:   git push --tags"
			echo "${script_name}:   git push -u origin ${new_rc_str}"
			echo "${script_name}: "

		fi

	else

		echo "${script_name}: could not find '${gitdir}' directory; bailing out."

	fi


	# Exit peacefully.
	return 0
}


# The script's main entry point, passing all parameters given.
main "$@"
