#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('UML::PlantUML::Encoder') || print "Bail out!\n";
}

#diag(
#    "Testing UML::PlantUML::Encoder $UML::PlantUML::Encoder::VERSION, Perl $], $^X"
#);
