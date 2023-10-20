#!/bin/bash

set -e

DOCKER_TAG=uid2-client-cpp-build

docker build . -t "${DOCKER_TAG}"

docker run -it --rm \
	-v "${PWD}:${PWD}" \
	-u $(id -u ${USER}):$(id -g ${USER}) \
	-e "HOME=${HOME}" -e "USER=${USER}" \
	-w "${PWD}" \
	"${DOCKER_TAG}" \
	"$@"
