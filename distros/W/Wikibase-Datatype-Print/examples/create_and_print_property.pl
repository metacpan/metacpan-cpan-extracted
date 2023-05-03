#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Datatype::Print::Property;
use Wikibase::Datatype::Property;
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

# Statement.
my $statement1 = Wikibase::Datatype::Statement->new(
        # instance of (P31) Wikidata property (Q18616576)
        'snak' => Wikibase::Datatype::Snak->new(
                'datatype' => 'wikibase-item',
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q18616576',
                ),
                'property' => 'P31',
        ),
);

# Main item.
my $obj = Wikibase::Datatype::Property->new(
        'aliases' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => 'je',
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'en',
                        'value' => 'is a',
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'en',
                        'value' => 'is an',
                ),
        ],
        'datatype' => 'wikibase-item',
        'descriptions' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => decode_utf8('tato položka je jedna konkrétní věc (exemplář, '.
                                'příklad) patřící do této třídy, kategorie nebo skupiny předmětů'),
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'en',
                        'value' => 'that class of which this subject is a particular example and member',
                ),
        ],
        'id' => 'P31',
        'labels' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => decode_utf8('instance (čeho)'),
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'en',
                        'value' => 'instance of',
                ),
        ],
        'page_id' => 3918489,
        'statements' => [
                $statement1,
        ],
        'title' => 'Property:P31',
);

# Print.
print encode_utf8(scalar Wikibase::Datatype::Print::Property::print($obj))."\n";

# Output:
# Data type: wikibase-item
# Label: instance of (en)
# Description: that class of which this subject is a particular example and member (en)
# Aliases:
#   is a (en)
#   is an (en)
# Statements:
#   P31: Q18616576 (normal)