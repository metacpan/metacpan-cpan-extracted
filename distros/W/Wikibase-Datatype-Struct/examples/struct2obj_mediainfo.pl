#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Struct::Mediainfo qw(struct2obj);

# Item structure.
my $struct_hr = {
        'descriptions' => {},
        'id' => 'Q42',
        'labels' => {
                'cs' => {
                        'language' => 'cs',
                        'value' => 'Douglas Adams',
                },
                'en' => {
                        'language' => 'en',
                        'value' => 'Douglas Adams',
                },
        },
        'ns' => 6,
        'pageid' => 123,
        'statements' => {
                'P21' => [{
                        'mainsnak' => {
                                'datavalue' => {
                                        'type' => 'wikibase-entityid',
                                        'value' => {
                                                'entity-type' => 'item',
                                                'id' => 'Q6581097',
                                                'numeric-id' => 6581097,
                                        },
                                },
                                'property' => 'P21',
                                'snaktype' => 'value',
                        },
                        'rank' => 'normal',
                        'type' => 'statement',
                }],
                'P31' => [{
                        'mainsnak' => {
                                'datavalue' => {
                                        'type' => 'wikibase-entityid',
                                        'value' => {
                                                'entity-type' => 'item',
                                                'id' => 'Q5',
                                                'numeric-id' => 5,
                                        },
                                },
                                'property' => 'P31',
                                'snaktype' => 'value',
                        },
                        'qualifiers' => {
                                'P642' => [{
                                        'datavalue' => {
                                                'type' => 'wikibase-entityid',
                                                'value' => {
                                                        'entity-type' => 'item',
                                                        'id' => 'Q474741',
                                                        'numeric-id' => 474741,
                                                }
                                        },
                                        'property' => 'P642',
                                        'snaktype' => 'value',
                                }],
                        },
                        'qualifiers-order' => [
                                'P642',
                        ],
                        'rank' => 'normal',
                        'type' => 'statement',
                }],
        },
        'title' => 'Q42',
        'type' => 'mediainfo',
};

# Get object.
my $obj = struct2obj($struct_hr);

# Print out.
p $obj;

# Output:
# Wikibase::Datatype::Mediainfo  {
#     parents: Mo::Object
#     public methods (5):
#         BUILD
#         Error::Pure:
#             err
#         Mo::utils:
#             check_array_object, check_number, check_number_of_items
#     private methods (0)
#     internals: {
#         descriptions   [],
#         id             "Q42",
#         labels         [
#             [0] Wikibase::Datatype::Value::Monolingual,
#             [1] Wikibase::Datatype::Value::Monolingual
#         ],
#         ns             6,
#         page_id        123,
#         statements     [
#             [0] Wikibase::Datatype::MediainfoStatement,
#             [1] Wikibase::Datatype::MediainfoStatement
#         ],
#         title          "Q42"
#     }
# }