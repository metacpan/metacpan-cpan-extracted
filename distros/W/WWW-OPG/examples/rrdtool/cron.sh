#!/bin/sh

# examples/cron.sh
#  A small wrapper script for running scripts using crontab
#
# $Id: cron.sh 10660 2009-12-28 14:41:35Z FREQUENCY@cpan.org $

# Failures should be fatal
set -e

# Change this to the path where your files are stored (your database,
# and either symlinks to files or the files themselves)
DATAPATH=/home/jon/rrdtool
# Path to Perl binary
PERL=/usr/bin/perl

# If WWW::OPG isn't system-installed, you need PERL5LIB
export PERL5LIB=/home/jon/cpan/WWW-OPG/lib

# Run this script via crontab using these example crontab entries:
#  # m h dom mon dow        command
#  7 * * * *                /home/jon/rrdtool/cron.sh update.pl
#  */5 * * * *              /home/jon/rrdtool/cron.sh graph.pl

if [ -z $1 ]; then
  echo "Usage: $0 <script>"
  exit
fi

cd $DATAPATH

$PERL $1 >/dev/null
