#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(encode_utf8);
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Wikibase::Datatype::Print::Utils qw(print_descriptions);
use Wikibase::Datatype::Print::Value::Monolingual;

my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
my @ret = print_descriptions($obj, {'lang' => 'cs'},
        \&Wikibase::Datatype::Print::Value::Monolingual::print);

# Print.
print encode_utf8(join "\n", @ret);
print "\n";

# Output:
# Description: domácí zvíře (cs)