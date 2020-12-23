#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Reference qw(struct2obj);

# Item structure.
my $struct_hr = {
        'snaks' => {
                'P214' => [{
                        'datatype' => 'external-id',
                        'datavalue' => {
                                'type' => 'string',
                                'value' => '113230702',
                        },
                        'property' => 'P214',
                        'snaktype' => 'value',
                }],
                'P248' => [{
                        'datatype' => 'wikibase-item',
                        'datavalue' => {
                                'type' => 'wikibase-entityid',
                                'value' => {
                                        'entity-type' => 'item',
                                        'id' => 'Q53919',
                                        'numeric-id' => 53919,
                                },
                        },
                        'property' => 'P248',
                        'snaktype' => 'value',
                }],
                'P813' => [{
                        'datatype' => 'time',
                        'datavalue' => {
                                'type' => 'time',
                                'value' => {
                                        'after' => 0,
                                        'before' => 0,
                                        'calendarmodel' => 'http://test.wikidata.org/entity/Q1985727',
                                        'precision' => 11,
                                        'time' => '+2013-12-07T00:00:00Z',
                                        'timezone' => 0,
                                },
                        },
                        'property' => 'P813',
                        'snaktype' => 'value',
                }],
        },
        'snaks-order' => [
                'P248',
                'P214',
                'P813',
        ],
};

# Get object.
my $obj = struct2obj($struct_hr);

# Get value.
my $snaks_ar = $obj->snaks;

# Print out number of snaks.
print "Number of snaks: ".@{$snaks_ar}."\n";

# Output:
# Number of snaks: 3