#!/usr/local/bin/perl

#
# unit test for XML::Toolset
#

use strict;
use Test::More qw(no_plan);
use App::Options;

#Due to warning about INIT block not being run in XML::Xerces
BEGIN {$^W = 0}

chdir($1) if ($0 =~ /(.*)(\/|\\)(.*)/);
unshift @INC, "../lib";

require XML::Toolset;
ok(1, "compiled version $XML::Toolset::VERSION");

