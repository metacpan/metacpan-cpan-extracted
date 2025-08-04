#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Wikibase::Datatype::Query;

my $obj = Wikibase::Datatype::Query->new;

my $item = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;

my $ret = $obj->query_lexeme($item, 'P5185');

print "Query for P5185 property on Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun:\n";
print $ret."\n";

# Output like:
# Query for P5185 property on Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun:
# Q499327