#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Struct::Lexeme qw(struct2obj);

# Lexeme structure.
my $struct_hr = {
        'grammaticalFeatures' => [
                'Q163012',
                'Q163014',
        ],
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
        'type' => 'lexeme',
};

# Get object.
my $obj = struct2obj($struct_hr);

# Dump object.
p $obj;

# Output:
# Wikibase::Datatype::Lexeme  {
#     Parents       Mo::Object
#     public methods (8) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), check_array_object (Mo::utils), check_entity (Wikibase::Datatype::Utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo::is)
#     internals: {
#         grammatical_features   [
#             [0] Wikibase::Datatype::Value::Item,
#             [1] Wikibase::Datatype::Value::Item
#         ],
#         id                     undef,
#         representations        [
#             [0] Wikibase::Datatype::Value::Monolingual,
#             [1] Wikibase::Datatype::Value::Monolingual
#         ],
#         statements             [
#             [0] Wikibase::Datatype::Statement
#         ]
#     }
# }