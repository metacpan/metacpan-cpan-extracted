#!/bin/sh

VERSION=$1
APP=tor-$VERSION.`uname -s`
APP=`echo $APP | tr A-Z a-z`

rm -f $APP

pp -I lib -o $APP -M Getopt::GUI::Long -M TheOneRing::CVS -M TheOneRing::GIT -M TheOneRing::SVN -M TheOneRing::SVK tor
