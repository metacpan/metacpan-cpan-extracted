#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Wikibase::Datatype::Query;

my $obj = Wikibase::Datatype::Query->new;

my $item = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;

my $ret = $obj->query_item($item, 'P31');

print "Query for P31 property on Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog:\n";
print $ret."\n";

# Output like:
# Query for P31 property on Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog:
# Q55983715