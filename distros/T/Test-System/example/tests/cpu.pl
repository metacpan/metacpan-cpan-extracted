#!/usr/bin/perl
# 
# cpu.pl
# 
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/13/2009 18:59:11 PST 18:59:11

use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::System::Helper;
use Data::Dumper;

my @nodes = get_nodes();
foreach my $node (@nodes) {
    isa_ok(\$node, 'SCALAR');
}

