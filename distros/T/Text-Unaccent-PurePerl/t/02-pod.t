# -*- mode: perl; coding: us-ascii-unix -*-
#
# Author:      Peter John Acklam
# Time-stamp:  2013-03-01 13:40:37 +00:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

#########################

#use 5.006;              # for the 'utf8' and 'warnings' pragmas
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
#use utf8;               # enable/disable UTF-8 (or UTF-EBCDIC) in source code

use Test::More;         # yet another framework for writing test scripts

# Ensure a recent version of Test::Pod

my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
