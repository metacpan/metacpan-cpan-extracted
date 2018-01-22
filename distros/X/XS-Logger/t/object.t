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

my $logger = XS::Logger->new();
isa_ok $logger, 'XS::Logger';
is $logger->get_pid(),   0, "get_pid = 0 by default";
is $logger->use_color(), 1, "use_color = 1 by default";

undef $logger;    # trigger destroy
is $logger, undef;
$logger = XS::Logger->new( { color => 0 } );
isa_ok $logger, 'XS::Logger';
is $logger->use_color(), 0, "use_color = 0";

done_testing;
