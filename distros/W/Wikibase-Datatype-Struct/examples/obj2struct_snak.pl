#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Struct::Snak qw(obj2struct);
use Wikibase::Datatype::Value::Item;

# Object.
# instance of (P31) human (Q5)
my $obj = Wikibase::Datatype::Snak->new(
         'datatype' => 'wikibase-item',
         'datavalue' => Wikibase::Datatype::Value::Item->new(
                 'value' => 'Q5',
         ),
         'property' => 'P31',
);

# Get structure.
my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     datatype    "wikibase-item",
#     datavalue   {
#         type    "wikibase-entityid",
#         value   {
#             entity-type   "item",
#             id            "Q5",
#             numeric-id    5
#         }
#     },
#     property    "P31",
#     snaktype    "value"
# }