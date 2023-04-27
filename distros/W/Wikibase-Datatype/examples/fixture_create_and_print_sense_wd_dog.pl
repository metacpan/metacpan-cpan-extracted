#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;
use Unicode::UTF8 qw(encode_utf8);
use Wikibase::Datatype::Print::Sense;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog->new;

# Print out.
print encode_utf8(scalar Wikibase::Datatype::Print::Sense::print($obj));

# Output:
# Id: L469-S1
# Glosses:
#   domesticated mammal related to the wolf (en)
#   psovitá šelma chovaná jako domácí zvíře (cs)
# Statements:
#   P18: Canadian Inuit Dog.jpg (normal)
#   P5137: Q144 (normal)