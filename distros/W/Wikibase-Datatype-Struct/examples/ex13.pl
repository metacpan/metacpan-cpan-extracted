#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Struct::MediainfoStatement qw(obj2struct);
use Wikibase::Datatype::Value::Item;

# Object.
my $obj = Wikibase::Datatype::MediainfoStatement->new(
        'id' => 'M123$00C04D2A-49AF-40C2-9930-C551916887E8',

        # instance of (P31) human (Q5)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q5',
                 ),
                 'property' => 'P31',
        ),
        'property_snaks' => [
                # of (P642) alien (Q474741)
                Wikibase::Datatype::MediainfoSnak->new(
                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                 'value' => 'Q474741',
                         ),
                         'property' => 'P642',
                ),
        ],
);

# Get structure.
my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     id                 "M123$00C04D2A-49AF-40C2-9930-C551916887E8",
#     mainsnak           {
#         datavalue   {
#             type    "wikibase-entityid",
#             value   {
#                 entity-type   "item",
#                 id            "Q5",
#                 numeric-id    5
#             }
#         },
#         property    "P31",
#         snaktype    "value"
#     },
#     qualifiers         {
#         P642   [
#             [0] {
#                 datavalue   {
#                     type    "wikibase-entityid",
#                     value   {
#                         entity-type   "item",
#                         id            "Q474741",
#                         numeric-id    474741
#                     }
#                 },
#                 property    "P642",
#                 snaktype    "value"
#             }
#         ]
#     },
#     qualifiers-order   [
#         [0] "P642"
#     ],
#     rank               "normal",
#     type               "statement"
# }