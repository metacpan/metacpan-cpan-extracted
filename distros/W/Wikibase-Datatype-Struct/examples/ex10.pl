#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Struct::Item qw(struct2obj);

# Item structure.
my $struct_hr = {
        'aliases' => {
                'en' => [{
                        'language' => 'en',
                        'value' => 'Douglas Noel Adams',
                }, {
                        'language' => 'en',
                        'value' => 'Douglas Noël Adams',
                }],
                'cs' => [{
                        'language' => 'cs',
                        'value' => 'Douglas Noel Adams',
                }, {
                        'language' => 'cs',
                        'value' => 'Douglas Noël Adams',
                }],
        },
        'claims' => {
                'P394' => [{
                        'rank' => 'normal',
                        'id' => 'Q42$c763016e-49e0-89b9-f717-2b18af5148f9',
                        'references' => [{
                                'hash' => 'ed9d0472fca124cea519c0a37eba5f33f10baa22',
                                'snaks' => {
                                        'P1943' => [{
                                                'datavalue' => {
                                                        'type' => 'string',
                                                        'value' => 'http://wikipedia.org/',
                                                },
                                                'datatype' => 'url',
                                                'snaktype' => 'value',
                                                'hash' => 'b808d4d54bed4daf07d9ac73353c0d1173cfa3c0',
                                                'property' => 'P1943',
                                        }],
                                },
                                'snaks-order' => [
                                        'P1943',
                                ],
                        }],
                        'type' => 'statement',
                        'mainsnak' => {
                                'datatype' => 'quantity',
                                'datavalue' => {
                                        'type' => 'quantity',
                                        'value' => {
                                                'amount' => '+0.00000000000000000000000000000091093821500',
                                                'upperBound' => '+0.00000000000000000000000000000091093821545',
                                                'lowerBound' => '+0.00000000000000000000000000000091093821455',
                                                'unit' => 'http://test.wikidata.org/entity/Q213',
                                        },
                                },
                                'snaktype' => 'value',
                                'hash' => 'fac57bc5b94714fb2390cce90f58b6a6cf9b9717',
                                'property' => 'P394',
                        },
                }],
        },
        'descriptions' => {
                'en' => {
                        'language' => 'en',
                        'value' => 'human',
                },
                'cs' => {
                        'language' => 'cs',
                        'value' => 'člověk',
                },
        },
        'id' => 'Q42',
        'labels' => {
                'en' => {
                        'language' => 'en',
                        'value' => 'Douglas Adams',
                },
                'cs' => {
                        'language' => 'cs',
                        'value' => 'Douglas Adams',
                },
        },
        'lastrevid' => 534820,
        'modified' => '2020-12-02T13:39:18Z',
        'ns' => 0,
        'pageid' => '703',
        'sitelinks' => {
                'cswiki' => {
                        'title' => 'Douglas Adams',
                        'badges' => [],
                        'site' => 'cswiki',
                },
        },
        'type' => 'item',
        'title' => 'Q42',
};

# Get object.
my $obj = struct2obj($struct_hr);

# Print out.
p $obj;

# Output:
# Wikibase::Datatype::Item  {
#     Parents       Mo::Object
#     public methods (9) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), check_array_object (Mo::utils), check_number (Mo::utils), check_number_of_items (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo::build)
#     internals: {
#         aliases        [
#             [0] Wikibase::Datatype::Value::Monolingual,
#             [1] Wikibase::Datatype::Value::Monolingual,
#             [2] Wikibase::Datatype::Value::Monolingual,
#             [3] Wikibase::Datatype::Value::Monolingual
#         ],
#         descriptions   [
#             [0] Wikibase::Datatype::Value::Monolingual,
#             [1] Wikibase::Datatype::Value::Monolingual
#         ],
#         id             "Q42",
#         labels         [
#             [0] Wikibase::Datatype::Value::Monolingual,
#             [1] Wikibase::Datatype::Value::Monolingual
#         ],
#         lastrevid      534820,
#         modified       "2020-12-02T13:39:18Z",
#         ns             0,
#         page_id        703,
#         sitelinks      [
#             [0] Wikibase::Datatype::Sitelink
#         ],
#         statements     [
#             [0] Wikibase::Datatype::Statement
#         ],
#         title          "Q42"
#     }
# }