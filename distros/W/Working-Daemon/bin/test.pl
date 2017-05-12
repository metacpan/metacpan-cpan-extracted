#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use Working::Daemon;
our $VERSION = 0.45;
my $daemon = Working::Daemon->new();
$daemon->name("testdaemon");
$daemon->standard("bool"      => "Test if you can set bools",
                  "integer=i" => "Integer settings",
                  "string=s"  => "String setting",
                  "multi=s%"  => "Multiset variable");



sleep 10;
1;
