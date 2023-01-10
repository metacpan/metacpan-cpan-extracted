#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Unicode::UTF8 qw(encode_utf8);
use Wikibase::Datatype::Print::Item;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;

# Print out.
print encode_utf8(scalar Wikibase::Datatype::Print::Item::print($obj));

# Output:
# Label: dog (en)
# Description: domestic animal (en)
# Aliases:
#   domestic dog (en)
#   Canis lupus familiaris (en)
#   Canis familiaris (en)
#   dogs (en)
#   🐶 (en)
#   🐕 (en)
# Sitelinks:
#   Dog (enwiki)
# Statements:
#   P31: Q55983715 (normal)
#    P642: Q20717272
#    P642: Q26972265