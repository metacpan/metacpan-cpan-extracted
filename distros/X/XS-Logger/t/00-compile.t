#!/bin/env perl

# compile.t
#
# Ensure the module compiles.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

# make sure the module compiles
ok eval { require XS::Logger; 1 }, "load XS::Logger" or diag $@;

is XS::Logger::_loaded(), 1, "XS BOOT";
is $XS::Logger::PATH_FILE, "/var/log/xslogger.log", "default PATH_FILE";

$XS::Logger::PATH_FILE = "another/path";    # avoid use once warning
is $XS::Logger::PATH_FILE, "another/path", "can overwrite path";

done_testing;
