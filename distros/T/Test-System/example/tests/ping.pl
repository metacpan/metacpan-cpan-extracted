#!/usr/bin/perl
# 
# ping.pl
# 
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/08/2009 21:59:13 PST 21:59:13

use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::System::Helper;
use Data::Dumper;


my @nodes = get_nodes();
foreach my $node (@nodes) {
    my $result = ok($node eq 'pablo.com.mx', $node);
    if (!$result) {
        note("$node is not pablo.com.mx");
    }
#    is($node, 'pablo.com.mx', "Is pablo.com.mx");
}
note("everything is full of foobar");

