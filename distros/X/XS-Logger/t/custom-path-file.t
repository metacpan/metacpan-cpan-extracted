#!/bin/env perl

use strict;
use warnings;

package XS::Logger;
our $PATH_FILE;

BEGIN {
    $XS::Logger::PATH_FILE = "/my/custom/path/before/loading/XS-Logger";
}

package main;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use XS::Logger;

is $XS::Logger::PATH_FILE, "/my/custom/path/before/loading/XS-Logger", "path preserved after loading the package";
is XS::Logger::_loaded(), 1, "XS BOOT";

done_testing;
