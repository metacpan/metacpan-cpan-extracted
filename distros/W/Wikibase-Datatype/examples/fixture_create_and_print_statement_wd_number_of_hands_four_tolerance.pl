#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::FourTolerance;
use Unicode::UTF8 qw(encode_utf8);
use Wikibase::Datatype::Print::Statement;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::FourTolerance->new;

# Print out.
print scalar encode_utf8(Wikibase::Datatype::Print::Statement::print($obj));

# Output:
# P123456789: 4±1 (normal)