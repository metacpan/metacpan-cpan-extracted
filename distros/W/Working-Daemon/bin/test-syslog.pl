#!/usr/bin/perl

use strict;
use warnings;

use Working::Daemon::Syslog;
use Data::Dumper;
my $daemon = Working::Daemon::Syslog->new();
our $VERSION = 0.45;

$daemon->name("testdaemon");
$daemon->standard("bool"      => "Test if you can set bools",
                  "integer=i" => "Integer settings",
                  "string=s"  => "String setting",
                  "multi=s%"  => "Multiset variable");


sleep 10;
1;
