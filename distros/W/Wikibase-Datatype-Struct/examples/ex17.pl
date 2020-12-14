#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Sense;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Struct::Sense qw(obj2struct);
use Wikibase::Datatype::Value::Item;
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
my $obj = Wikibase::Datatype::Sense->new(
        'glosses' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'en',
                        'value' => 'Glosse en',
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => 'Glosse cs',
                ),
        ],
        'id' => 'ID',
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
#     glosses      {
#         cs   {
#             language   "cs",
#             value      "Glosse cs"
#         },
#         en   {
#             language   "en",
#             value      "Glosse en"
#         }
#     },
#     id           "ID",
#     claims   {
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
#     }
# }