#!/bin/bash
set -u
set -e

# Dependencies: jq git aptly realpath wget gettext-base
# Setup: aptly repo create -config=/path/to/aptly.conf --distribution=any --component=main vagrant-deb
GPG_KEY=2099F7A4

BASEDIR=$(dirname $(realpath $0))
VERSION=$(wget -q -O - https://bintray.com/api/v1/packages/mitchellh/otto/otto/ | jq -r .latest_version)

# The choice of aptly was entirely arbitrary, but works fine.
aptly="aptly -config=$BASEDIR/aptly.conf"

if ! $aptly snapshot list | grep otto-$VERSION > /dev/null; then
	mkdir /tmp/otto-$VERSION
	cd /tmp/otto-$VERSION
	
	# Download the packages
	for package in otto_${VERSION}_{x86_64,i686}.deb; do
		wget -nv https://dl.bintray.com/mitchellh/otto/$package
	done
	
	# Add the packages to aptly
	$aptly repo add otto-deb .
	$aptly snapshot create otto-$VERSION from repo otto-deb

	$aptly publish switch any otto-$VERSION
	
	# Clean up after ourselves
	cd
	rm /tmp/otto-$VERSION/*
	rmdir /tmp/otto-$VERSION
fi

# Export variables for templating
export VERSION
export NOW=$(date +%F)
export GPG_KEY
cat $BASEDIR/index.tpl | envsubst > $BASEDIR/public_html/index.html
