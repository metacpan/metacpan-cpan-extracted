#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Struct::Form qw(struct2obj);

# Item structure.
my $struct_hr = {
        'grammaticalFeatures' => [
                'Q163012',
                'Q163014',
        ],
        'id' => 'ID',
        'representations' => {
                'cs' => {
                        'language' => 'cs',
                        'value' => 'Representation cs',
                },
                'en' => {
                        'language' => 'en',
                        'value' => 'Representation en',
                },
        },
        'claims' => {
                'P31' => [{
                        'mainsnak' => {
                                'datatype' => 'wikibase-item',
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
                        'rank' => 'normal',
                        'type' => 'statement',
                }],
        },
};

# Get object.
my $obj = struct2obj($struct_hr);

# Dump object.
p $obj;

# Output:
# Wikibase::Datatype::Form  {
#     Parents       Mo::Object
#     public methods (6) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), check_array_object (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo::is)
#     internals: {
#         grammatical_features   [
#             [0] Wikibase::Datatype::Value::Item,
#             [1] Wikibase::Datatype::Value::Item
#         ],
#         id                     "ID",
#         represenations         undef,
#         statements             [
#             [0] Wikibase::Datatype::Statement
#         ]
#     }
# }