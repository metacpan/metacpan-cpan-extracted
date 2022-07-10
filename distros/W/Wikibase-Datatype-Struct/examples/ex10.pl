#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Struct::Property qw(struct2obj);

# Item structure.
my $struct_hr = {
        'aliases' => {
                'cs' => [{
                        'language' => 'cs',
                        'value' => 'je',
                }],
                'en' => [{
                        'language' => 'en',
                        'value' => 'is a',
                }, {
                        'language' => 'en',
                        'value' => 'is an',
                }],
        },
        'claims' => {
                'P31' => [{
                        'mainsnak' => {
                                'datatype' => 'wikibase-item',
                                'datavalue' => {
                                        'type' => 'wikibase-entityid',
                                        'value' => {
                                                'entity-type' => 'item',
                                                'id' => 'Q18616576',
                                                'numeric-id' => 18616576,
                                        },
                                },
                                'property' => 'P31',
                                'snaktype' => 'value',
                        },
                        'rank' => 'normal',
                        'type' => 'statement',
                }],
        },
        'datatype' => 'wikibase-item',
        'descriptions' => {
                'cs' => {
                        'language' => 'cs',
                        'value' => decode_utf8('tato položka je jedna konkrétní věc (exemplář, příklad) patřící do této třídy, kategorie nebo skupiny předmětů'),
                },
                'en' => {
                        'language' => 'en',
                        'value' => 'that class of which this subject is a particular example and member',
                },
        },
        'id' => 'P31',
        'labels' => {
                'cs' => {
                        'language' => 'cs',
                        'value' => decode_utf8('instance (čeho)'),
                },
                'en' => {
                        'language' => 'en',
                        'value' => 'instance of',
                },
        },
        'ns' => 120,
        'pageid' => 3918489,
        'title' => 'Property:P31',
        'type' => 'property',
};

# Get object.
my $obj = struct2obj($struct_hr);

# Print out.
p $obj;

# Output:
# Wikibase::Datatype::Property  {
#     parents: Mo::Object
#     public methods (8):
#         BUILD
#         Error::Pure:
#             err
#         List::Util:
#             none
#         Mo::utils:
#             check_array_object, check_number, check_number_of_items, check_required
#         Readonly:
#             Readonly
#     private methods (0)
#     internals: {
#         aliases        [
#             [0] Wikibase::Datatype::Value::Monolingual,
#             [1] Wikibase::Datatype::Value::Monolingual,
#             [2] Wikibase::Datatype::Value::Monolingual
#         ],
#         datatype       "wikibase-item",
#         descriptions   [
#             [0] Wikibase::Datatype::Value::Monolingual,
#             [1] Wikibase::Datatype::Value::Monolingual
#         ],
#         id             "P31",
#         labels         [
#             [0] Wikibase::Datatype::Value::Monolingual,
#             [1] Wikibase::Datatype::Value::Monolingual
#         ],
#         ns             120,
#         page_id        3918489,
#         statements     [
#             [0] Wikibase::Datatype::Statement
#         ],
#         title          "Property:P31"
#     }
# }