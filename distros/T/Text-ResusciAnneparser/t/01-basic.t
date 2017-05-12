#!/bin/bin/perl
#
# Copyright (C) 2013 by Lieven Hollevoet

# This test runs basic module tests

use strict;
use Test::More;

BEGIN { use_ok 'Text::ResusciAnneparser'; }
BEGIN { use_ok 'Test::Exception'; }
require Test::Exception;

# Check we get an error message on missing input parameters
my $parser;

can_ok ('Text::ResusciAnneparser', qw(infile certified in_training));

throws_ok { $parser = Text::ResusciAnneparser->new() } qr/Attribute .+ is required/, "Checking missing parameters";
throws_ok { $parser = Text::ResusciAnneparser->new(infile => 't/stim/missing_file.xml') } qr/File does not exist.+/, "Checking missing xml file";

$parser = Text::ResusciAnneparser->new(infile => 't/stim/certificates.xml');
ok $parser, 'object created';
ok $parser->isa('Text::ResusciAnneparser'), 'and it is the right class';

my $certified = $parser->certified();
my $training  = $parser->in_training();

is $certified->{'2012-10-03'}->[0]->{givenname}, 'Three', "Found expected certified person";
is scalar(@{$training}), 3, "Found 3 people in training";

# Verify we remove trailing/leading spaces from names
is $certified->{'2012-10-10'}->[0]->{givenname}, 'Four', "Givenname cleanup";
is $certified->{'2012-10-10'}->[0]->{familyname}, 'User', "Familyname cleanup";

done_testing();