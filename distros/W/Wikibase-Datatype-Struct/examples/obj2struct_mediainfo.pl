#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Mediainfo;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Struct::Mediainfo qw(obj2struct);
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;

# Object.
my $statement1 = Wikibase::Datatype::MediainfoStatement->new(
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
my $statement2 = Wikibase::Datatype::MediainfoStatement->new(
        # sex or gender (P21) male (Q6581097)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q6581097',
                ),
                'property' => 'P21',
        ),
);

# Main item.
my $obj = Wikibase::Datatype::Mediainfo->new(
        'id' => 'Q42',
        'labels' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => 'Douglas Adams',
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'en',
                        'value' => 'Douglas Adams',
                ),
        ],
        'page_id' => 123,
        'statements' => [
                $statement1,
                $statement2,
        ],
        'title' => 'Q42',
);

# Get structure.
my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

# Dump to output.
p $struct_hr;

# Output:
# {
#     descriptions   {},
#     id             "Q42",
#     labels         {
#         cs   {
#             language   "cs",
#             value      "Douglas Adams"
#         },
#         en   {
#             language   "en",
#             value      "Douglas Adams"
#         }
#     },
#     ns             6,
#     pageid         123,
#     statements     {
#         P21   [
#             [0] {
#                     mainsnak   {
#                         datavalue   {
#                             type    "wikibase-entityid",
#                             value   {
#                                 entity-type   "item",
#                                 id            "Q6581097",
#                                 numeric-id    6581097
#                             }
#                         },
#                         property    "P21",
#                         snaktype    "value"
#                     },
#                     rank       "normal",
#                     type       "statement"
#                 }
#         ],
#         P31   [
#             [0] {
#                     mainsnak           {
#                         datavalue   {
#                             type    "wikibase-entityid",
#                             value   {
#                                 entity-type   "item",
#                                 id            "Q5",
#                                 numeric-id    5
#                             }
#                         },
#                         property    "P31",
#                         snaktype    "value"
#                     },
#                     qualifiers         {
#                         P642   [
#                             [0] {
#                                     datavalue   {
#                                         type    "wikibase-entityid",
#                                         value   {
#                                             entity-type   "item",
#                                             id            "Q474741",
#                                             numeric-id    474741
#                                         }
#                                     },
#                                     property    "P642",
#                                     snaktype    "value"
#                                 }
#                         ]
#                     },
#                     qualifiers-order   [
#                         [0] "P642"
#                     ],
#                     rank               "normal",
#                     type               "statement"
#                 }
#         ]
#     },
#     title          "Q42",
#     type           "mediainfo"
# }