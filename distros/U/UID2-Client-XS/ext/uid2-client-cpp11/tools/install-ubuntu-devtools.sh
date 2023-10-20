#!/bin/bash

set -ex

apt-get update
apt-get install -y \
	build-essential \
	clang-14 clang-format-14 clang-tidy-14 clangd-14 \
	cmake \
	gcc-11 g++11 \
	ninja-build

apt-get autoremove -y
apt-get clean -y
rm -rf /var/lib/apt/lists/*
