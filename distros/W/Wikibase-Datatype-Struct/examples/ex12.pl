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
# TODO