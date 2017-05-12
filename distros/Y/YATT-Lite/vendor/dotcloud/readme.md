This directory contains sample skeleton files to run yatt on dotcloud.
To use this, just do as followings:

* cp -va vendor/dotcloud  SOMEWHERE
* cd SOMEWHERE
* git init
* git submodule update --init # this will clone lib/YATT from github

Then you can:

* plackup
* dotcloud push YOUR_APP.www
