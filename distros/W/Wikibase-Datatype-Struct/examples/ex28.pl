#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Struct::Sense qw(struct2obj);

# Item structure.
my $struct_hr = {
        'glosses' => {
                'cs' => {
                        'language' => 'cs',
                        'value' => 'Glosse cs',
                },
                'en' => {
                        'language' => 'en',
                        'value' => 'Glosse en',
                },
        },
        'id' => 'ID',
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
# Wikibase::Datatype::Sense  {
#     Parents       Mo::Object
#     public methods (7) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), check_array_object (Mo::utils), check_number_of_items (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo)
#     internals: {
#         glosses      [
#             [0] Wikibase::Datatype::Value::Monolingual,
#             [1] Wikibase::Datatype::Value::Monolingual
#         ],
#         id           "ID",
#         statements   [
#             [0] Wikibase::Datatype::Statement
#         ]
#     }
# }