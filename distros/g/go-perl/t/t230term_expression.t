#!/usr/local/bin/perl -w

use lib '.';

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 1;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;
use Data::Stag;

my $parser = GO::Parser->new({format=>'obo_text'});
my $te = $parser->parse_term_expression("GO:1234^part_of(CL:abc)");
print $te->xml;
$te = $parser->parse_term_expression("GO:1234^part_of(CL:abc^part_of(AO:999))");
print $te->xml;
$te = $parser->parse_term_expression("GO:1234^part_of(CL:abc^part_of(AO:999)^has_coordinate(x:left))");
print $te->xml;
$te = $parser->parse_term_expression("(GO:1234^results_in_output_of(CHEBI:765))^part_of(CL:abc^part_of(AO:999)^has_coordinate(x:left))");
print $te->xml;
ok(1);
