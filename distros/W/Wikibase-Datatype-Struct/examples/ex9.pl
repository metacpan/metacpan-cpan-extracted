#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Property;
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Struct::Property qw(obj2struct);
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

# Main property.
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

# Get structure.
my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

# Dump to output.
p $struct_hr;

# Output:
# {
#     aliases        {
#         cs   [
#             [0] {
#                     language   "cs",
#                     value      "je"
#                 }
#         ],
#         en   [
#             [0] {
#                     language   "en",
#                     value      "is a"
#                 },
#             [1] {
#                     language   "en",
#                     value      "is an"
#                 }
#         ]
#     },
#     claims         {
#         P31   [
#             [0] {
#                     mainsnak   {
#                         datatype    "wikibase-item",
#                         datavalue   {
#                             type    "wikibase-entityid",
#                             value   {
#                                 entity-type   "item",
#                                 id            "Q18616576",
#                                 numeric-id    18616576
#                             }
#                         },
#                         property    "P31",
#                         snaktype    "value"
#                     },
#                     rank       "normal",
#                     type       "statement"
#                 }
#         ]
#     },
#     datatype       "wikibase-item",
#     descriptions   {
#         cs   {
#             language   "cs",
#             value      "tato položka je jedna konkrétní věc (exemplář, příklad) patřící do této třídy, kategorie nebo skupiny předmětů"
#         },
#         en   {
#             language   "en",
#             value      "that class of which this subject is a particular example and member"
#         }
#     },
#     id             "P31",
#     labels         {
#         cs   {
#             language   "cs",
#             value      "instance (čeho)"
#         },
#         en   {
#             language   "en",
#             value      "instance of"
#         }
#     },
#     ns             120,
#     pageid         3918489,
#     title          "Property:P31",
#     type           "property"
# }