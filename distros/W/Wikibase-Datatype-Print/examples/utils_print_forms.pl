#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(encode_utf8);
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Wikibase::Datatype::Print::Form;
use Wikibase::Datatype::Print::Utils qw(print_forms);

my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
my @ret = print_forms($obj, {'lang' => 'cs'},
        \&Wikibase::Datatype::Print::Form::print);

# Print.
print encode_utf8(join "\n", @ret);
print "\n";

# Output:
# Forms:
#   Id: L469-F1
#   Representation: pes (cs)
#   Grammatical features: Q110786, Q131105
#   Statements:
#     P898: pɛs (normal)