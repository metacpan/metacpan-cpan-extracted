#!/bin/bash

set -ex

apt-get update
apt-get -y install \
	libgtest-dev \
	libssl-dev

apt-get autoremove -y
apt-get clean -y
rm -rf /var/lib/apt/lists/*
