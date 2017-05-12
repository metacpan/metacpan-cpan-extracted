#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

n_tests(2);

my $apph = get_readonly_apph();
stmt_ok;

# lets check we got stuff

$apph->filters({evcodes=>["!IEA"]});
my $desc = 'transmembrane receptor activity';

my $pl1 = $apph->get_products({term=>{name=>$desc}});
my $pl2 = $apph->get_products({deep=>1, term=>{name=>$desc}});

my $n1 = scalar(@$pl1);
my $n2 = scalar(@$pl2);
printf "got $n1 and $n2\n";
stmt_check($n1 < $n2);
