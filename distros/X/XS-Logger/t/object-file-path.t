#!/bin/env perl

# compile.t
#
# Ensure the module compiles.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use XS::Logger;

is $XS::Logger::PATH_FILE, "/var/log/xslogger.log";

my $logger1 = XS::Logger->new( );
is $logger1->logfile, '/var/log/xslogger.log';

my $logger2 = XS::Logger->new( { logfile => q[/there] } );
is $logger2->logfile, '/there';

is $logger1->logfile, '/var/log/xslogger.log';


my $logger = XS::Logger->new;

$XS::Logger::PATH_FILE = q[/somewhere];
is $XS::Logger::PATH_FILE, q[/somewhere];

is $logger->logfile, q[/somewhere];

$XS::Logger::PATH_FILE = q[/over-there];
is $logger->logfile, q[/over-there];

done_testing;

