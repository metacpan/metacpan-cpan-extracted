#!/usr/local/bin/perl
# $Id: /local/WWW-RobotRules-DBIC/t/server.pl 16 2006-10-18T07:51:40.777451Z ikebe  $
#
# IKEBE Tomohiro <ikebe@livedoor.jp>
# Time-stamp: <2006-10-18 14:09:10 ikebe>
use strict;
use FindBin qw($Bin);
use lib "$Bin/lib";
use TestHttpd;

my $server = TestHttpd->new(@ARGV);
$server->run;

1;

__END__
