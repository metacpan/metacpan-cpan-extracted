#!/usr/bin/env bash
cd ..
rm -rf pod
cd lib/UR
ur update pod -i .. -o ../../pod ur UR::Namespace::Command
cd ../..
rm -rf pod/ur-old*
