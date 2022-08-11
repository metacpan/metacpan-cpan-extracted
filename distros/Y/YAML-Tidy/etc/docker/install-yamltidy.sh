#!/bin/sh

set -ex

HOME=/tmp/home
cpanm -l /tmp/yamltidy --notest YAML::Tidy@0.007
