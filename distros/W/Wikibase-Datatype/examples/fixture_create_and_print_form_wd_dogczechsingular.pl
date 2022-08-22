#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;
use Unicode::UTF8 qw(encode_utf8);
use Wikibase::Datatype::Print::Form;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new;

# Print out.
print encode_utf8(scalar Wikibase::Datatype::Print::Form::print($obj));

# Output:
# Id: L469-F1
# Representation: pes (cs)
# Grammatical features: Q110786, Q131105
# Statements:
#   P898: pɛs (normal)