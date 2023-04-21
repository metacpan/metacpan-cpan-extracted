#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Print::Form;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Monolingual;

# Object.
my $obj = Wikibase::Datatype::Form->new(
        'grammatical_features' => [
                # singular
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q110786',
                ),
                # nominative case
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q131105',
                ),
        ],
        'id' => 'L469-F1',
        'representations' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => 'pes',
                ),
        ],
        'statements' => [
                Wikibase::Datatype::Statement->new(
                        'snak' => Wikibase::Datatype::Snak->new(
                                'datatype' => 'string',
                                'datavalue' => Wikibase::Datatype::Value::String->new(
                                       'value' => decode_utf8('pɛs'),
                                ),
                                'property' => 'P898',
                        ),
                ),
        ],
);

# Print.
print encode_utf8(scalar Wikibase::Datatype::Print::Form::print($obj))."\n";

# Output:
# Id: L469-F1
# Representation: pes (cs)
# Grammatical features: Q110786, Q131105
# Statements:
#   P898: pɛs (normal)