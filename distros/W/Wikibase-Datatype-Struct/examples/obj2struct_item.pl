#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Struct::Item qw(obj2struct);
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

# Object.
my $statement1 = Wikibase::Datatype::Statement->new(
        # instance of (P31) human (Q5)
        'snak' => Wikibase::Datatype::Snak->new(
                'datatype' => 'wikibase-item',
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q5',
                ),
                'property' => 'P31',
        ),
        'property_snaks' => [
                # of (P642) alien (Q474741)
                Wikibase::Datatype::Snak->new(
                        'datatype' => 'wikibase-item',
                        'datavalue' => Wikibase::Datatype::Value::Item->new(
                                'value' => 'Q474741',
                        ),
                        'property' => 'P642',
                ),
        ],
        'references' => [
                Wikibase::Datatype::Reference->new(
                        'snaks' => [
                                # stated in (P248) Virtual International Authority File (Q53919)
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'wikibase-item',
                                        'datavalue' => Wikibase::Datatype::Value::Item->new(
                                                'value' => 'Q53919',
                                        ),
                                        'property' => 'P248',
                                ),

                                # VIAF ID (P214) 113230702
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'external-id',
                                        'datavalue' => Wikibase::Datatype::Value::String->new(
                                                'value' => '113230702',
                                        ),
                                        'property' => 'P214',
                                ),

                                # retrieved (P813) 7 December 2013
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'time',
                                        'datavalue' => Wikibase::Datatype::Value::Time->new(
                                                'value' => '+2013-12-07T00:00:00Z',
                                        ),
                                        'property' => 'P813',
                                ),
                        ],
                ),
        ],
);
my $statement2 = Wikibase::Datatype::Statement->new(
        # sex or gender (P21) male (Q6581097)
        'snak' => Wikibase::Datatype::Snak->new(
                'datatype' => 'wikibase-item',
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q6581097',
                ),
                'property' => 'P21',
        ),
        'references' => [
                Wikibase::Datatype::Reference->new(
                        'snaks' => [
                                # stated in (P248) Virtual International Authority File (Q53919)
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'wikibase-item',
                                        'datavalue' => Wikibase::Datatype::Value::Item->new(
                                                'value' => 'Q53919',
                                        ),
                                        'property' => 'P248',
                                ),

                                # VIAF ID (P214) 113230702
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'external-id',
                                        'datavalue' => Wikibase::Datatype::Value::String->new(
                                                'value' => '113230702',
                                        ),
                                        'property' => 'P214',
                                ),

                                # retrieved (P813) 7 December 2013
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'time',
                                        'datavalue' => Wikibase::Datatype::Value::Time->new(
                                                'value' => '+2013-12-07T00:00:00Z',
                                        ),
                                        'property' => 'P813',
                                ),
                        ],
                ),
        ],
);

# Main item.
my $obj = Wikibase::Datatype::Item->new(
        'aliases' => [
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => 'Douglas Noël Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => 'Douglas Noel Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => 'Douglas N. Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => 'Douglas Noel Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => 'Douglas Noël Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => 'Douglas N. Adams',
                ),
        ],
        'descriptions' => [
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => 'anglický spisovatel, humorista a dramatik',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => 'English writer and humorist',
                ),
        ],
        'id' => 'Q42',
        'labels' => [
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => 'Douglas Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => 'Douglas Adams',
                ),
        ],
        'page_id' => 123,
        'sitelinks' => [
                Wikibase::Datatype::Sitelink->new(
                        'site' => 'cswiki',
                        'title' => 'Douglas Adams',
                ),
                Wikibase::Datatype::Sitelink->new(
                        'site' => 'enwiki',
                        'title' => 'Douglas Adams',
                ),
        ],
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
# \ {
#     aliases        {
#         cs   [
#             [0] {
#                 language   "cs",
#                 value      "Douglas Noël Adams"
#             },
#             [1] {
#                 language   "cs",
#                 value      "Douglas Noel Adams"
#             },
#             [2] {
#                 language   "cs",
#                 value      "Douglas N. Adams"
#             }
#         ],
#         en   [
#             [0] {
#                 language   "en",
#                 value      "Douglas Noel Adams"
#             },
#             [1] {
#                 language   "en",
#                 value      "Douglas Noël Adams"
#             },
#             [2] {
#                 language   "en",
#                 value      "Douglas N. Adams"
#             }
#         ]
#     },
#     descriptions   {
#         cs   {
#             language   "cs",
#             value      "anglický spisovatel, humorista a dramatik"
#         },
#         en   {
#             language   "en",
#             value      "English writer and humorist"
#         }
#     },
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
#     ns             0,
#     pageid         123,
#     sitelinks      {
#         cswiki   {
#             badges   [],
#             site     "cswiki",
#             title    "Douglas Adams"
#         },
#         enwiki   {
#             badges   [],
#             site     "enwiki",
#             title    "Douglas Adams"
#         }
#     },
#     claims     {
#         P21   [
#             [0] {
#                 mainsnak     {
#                     datatype    "wikibase-item",
#                     datavalue   {
#                         type    "wikibase-entityid",
#                         value   {
#                             entity-type   "item",
#                             id            "Q6581097",
#                             numeric-id    6581097
#                         }
#                     },
#                     property    "P21",
#                     snaktype    "value"
#                 },
#                 rank         "normal",
#                 references   [
#                     [0] {
#                         snaks         {
#                             P214   [
#                                 [0] {
#                                     datatype    "external-id",
#                                     datavalue   {
#                                         type    "string",
#                                         value   113230702
#                                     },
#                                     property    "P214",
#                                     snaktype    "value"
#                                 }
#                             ],
#                             P248   [
#                                 [0] {
#                                     datatype    "wikibase-item",
#                                     datavalue   {
#                                         type    "wikibase-entityid",
#                                         value   {
#                                             entity-type   "item",
#                                             id            "Q53919",
#                                             numeric-id    53919
#                                         }
#                                     },
#                                     property    "P248",
#                                     snaktype    "value"
#                                 }
#                             ],
#                             P813   [
#                                 [0] {
#                                     datatype    "time",
#                                     datavalue   {
#                                         type    "time",
#                                         value   {
#                                             after           0,
#                                             before          0,
#                                             calendarmodel   "http://test.wikidata.org/entity/Q1985727",
#                                             precision       11,
#                                             time            "+2013-12-07T00:00:00Z",
#                                             timezone        0
#                                         }
#                                     },
#                                     property    "P813",
#                                     snaktype    "value"
#                                 }
#                             ]
#                         },
#                         snaks-order   [
#                             [0] "P248",
#                             [1] "P214",
#                             [2] "P813"
#                         ]
#                     }
#                 ],
#                 type         "statement"
#             }
#         ],
#         P31   [
#             [0] {
#                 mainsnak           {
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
#                 qualifiers         {
#                     P642   [
#                         [0] {
#                             datatype    "wikibase-item",
#                             datavalue   {
#                                 type    "wikibase-entityid",
#                                 value   {
#                                     entity-type   "item",
#                                     id            "Q474741",
#                                     numeric-id    474741
#                                 }
#                             },
#                             property    "P642",
#                             snaktype    "value"
#                         }
#                     ]
#                 },
#                 qualifiers-order   [
#                     [0] "P642"
#                 ],
#                 rank               "normal",
#                 references         [
#                     [0] {
#                         snaks         {
#                             P214   [
#                                 [0] {
#                                     datatype    "external-id",
#                                     datavalue   {
#                                         type    "string",
#                                         value   113230702
#                                     },
#                                     property    "P214",
#                                     snaktype    "value"
#                                 }
#                             ],
#                             P248   [
#                                 [0] {
#                                     datatype    "wikibase-item",
#                                     datavalue   {
#                                         type    "wikibase-entityid",
#                                         value   {
#                                             entity-type   "item",
#                                             id            "Q53919",
#                                             numeric-id    53919
#                                         }
#                                     },
#                                     property    "P248",
#                                     snaktype    "value"
#                                 }
#                             ],
#                             P813   [
#                                 [0] {
#                                     datatype    "time",
#                                     datavalue   {
#                                         type    "time",
#                                         value   {
#                                             after           0,
#                                             before          0,
#                                             calendarmodel   "http://test.wikidata.org/entity/Q1985727",
#                                             precision       11,
#                                             time            "+2013-12-07T00:00:00Z",
#                                             timezone        0
#                                         }
#                                     },
#                                     property    "P813",
#                                     snaktype    "value"
#                                 }
#                             ]
#                         },
#                         snaks-order   [
#                             [0] "P248",
#                             [1] "P214",
#                             [2] "P813"
#                         ]
#                     }
#                 ],
#                 type               "statement"
#             }
#         ]
#     },
#     title          "Q42",
#     type           "item"
# }