#!/usr/bin/perl -w
#
# 02_basic.t
#
# Copyright (C) 2001 Gregor N. Purdy.
# All rights reserved.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#


use strict;

BEGIN {
  print "1..1\n";
}

use XPC::Daemon;
use XPC::Agent;

#
# Set up to reap the child process when it dies:
#

use POSIX ":sys_wait_h";
sub REAPER { 1 until (waitpid(-1, WNOHANG) == -1) }
$SIG{CHLD} = \&REAPER;


#
# Set up the daemon:
#

my $daemon = new XPC::Daemon;
$daemon->debug(1); 

$daemon->add_procedure('localtime', sub { localtime });

my $url = $daemon->url;


#
# Fork off a server:
#

my $pid = fork;

die "$0: Unable to fork!\n" unless  defined $pid;

unless ($pid) {
  $daemon->run;
  exit 0;
}

sleep 1;


#
# Set up the agent and make a call:
#

print "$0: Using URL '$url'...\n";

my $agent = XPC::Agent->new($url);
$agent->debug(1);

printf "localtime() --> %s\n", $agent->localtime();

#
# Kill off the server:
#

kill INT => $pid;

waitpid $pid, WNOHANG;

print "ok 1\n";

exit 0;


#
# End of file.
#
