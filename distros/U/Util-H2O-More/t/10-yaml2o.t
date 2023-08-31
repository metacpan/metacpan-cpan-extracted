#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp      qw/tempfile/;
use Util::H2O::More qw/yaml2o/;

my $YAML = <<EOYAML;
---
database:
  host:     localhost
  port:     3306
  db:       users
  username: appuser
  password: 1uggagel2345
---
devices:
  copter1:
    active:  1
    macaddr: a0:ff:6b:14:19:6e
    host:    192.168.0.14
    port:    80
  thingywhirl:
    active:  1
    macaddr: 00:88:fb:1a:5f:08
    host:    192.168.0.14
    port:    80
EOYAML

my $NOT_YAML_OR_FILE = <<EONOTYAML;
MR DUCKS
AM R NOT
AM R 2
C DEM E D B D WANGS
L I C
MR DUCKS
EONOTYAML

dies_ok { yaml2o $NOT_YAML_OR_FILE } q{yaml2o passed something this is not a file name nor clearly not YAML.};

my ( $dbconfig1, $devices1 ) = yaml2o $YAML;

is $dbconfig1->database->host,        q{localhost}, q{YAML string parsed and objectified as expected};
is $devices1->devices->copter1->port, 80,           q{YAML string parsed and objectified as expected};

my ( $fh, $filename ) = tempfile( SUFFIX => '.yaml' );

print $fh $YAML;

my ( $dbconfig2, $devices2 ) = yaml2o $YAML;

is $dbconfig2->database->host,        q{localhost}, q{YAML file parsed and objectified as expected};
is $devices2->devices->copter1->port, 80,           q{YAML file parsed and objectified as expected};

done_testing;
