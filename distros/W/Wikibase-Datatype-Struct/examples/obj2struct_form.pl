#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Struct::Form qw(obj2struct);
use Wikibase::Datatype::Value::Monolingual;

# Statement.
my $statement = Wikibase::Datatype::Statement->new(
        # instance of (P31) human (Q5)
        'snak' => Wikibase::Datatype::Snak->new(
                'datatype' => 'wikibase-item',
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q5',
                ),
                'property' => 'P31',
        ),
);

# Object.
my $obj = Wikibase::Datatype::Form->new(
        'grammatical_features' => [
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q163012',
                ),
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q163014',
                ),
        ],
        'id' => 'ID',
        'representations' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'en',
                        'value' => 'Representation en',
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => 'Representation cs',
                ),
        ],
        'statements' => [
                $statement,
        ],
);

# Get structure.
my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     claims                {
#         P31   [
#             [0] {
#                 mainsnak   {
#                     datatype    "wikibase-item",
#                     datavalue   {
#                         type    "wikibase-entityid",
#                         value   {
#                             entity-type   "item",
#                             id            "Q5",
#                             numeric-id    5
#                         }
#                     },
#                     property    "P31",
#                     snaktype    "value"
#                 },
#                 rank       "normal",
#                 type       "statement"
#             }
#         ]
#     },
#     grammaticalFeatures   [
#         [0] "Q163012",
#         [1] "Q163014"
#     ],
#     id                    "ID",
#     represenations        {
#         cs   {
#             language   "cs",
#             value      "Representation cs"
#         },
#         en   {
#             language   "en",
#             value      "Representation en"
#         }
#     }
# }