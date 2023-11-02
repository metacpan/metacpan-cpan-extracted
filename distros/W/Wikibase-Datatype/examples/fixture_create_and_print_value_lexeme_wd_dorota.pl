#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Value::Lexeme::Wikidata::Dorota;
use Wikibase::Datatype::Print::Value::Lexeme;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Lexeme::Wikidata::Dorota->new;

# Print out.
print scalar Wikibase::Datatype::Print::Value::Lexeme::print($obj);

# Output:
# L42284