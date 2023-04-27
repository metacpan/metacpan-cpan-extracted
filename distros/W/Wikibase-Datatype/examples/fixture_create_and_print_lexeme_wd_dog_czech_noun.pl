#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Unicode::UTF8 qw(encode_utf8);
use Wikibase::Datatype::Print::Lexeme;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;

# Print out.
print encode_utf8(scalar Wikibase::Datatype::Print::Lexeme::print($obj));

# Output:
# Title: Lexeme:L469
# Lemmas: pes (cs)
# Language: Q9056
# Lexical category: Q1084
# Statements:
#   P5185: Q499327 (normal)
#   References:
#     {
#       P248: Q53919
#       P214: 113230702
#       P813: 7 December 2013 (Q1985727)
#     }
# Senses:
#   Id: L469-S1
#   Glosses:
#     domesticated mammal related to the wolf (en)
#     psovitá šelma chovaná jako domácí zvíře (cs)
#   Statements:
#     P18: Canadian Inuit Dog.jpg (normal)
#     P5137: Q144 (normal)
# Forms:
#   Id: L469-F1
#   Representation: pes (cs)
#   Grammatical features: Q110786, Q131105
#   Statements:
#     P898: pɛs (normal)