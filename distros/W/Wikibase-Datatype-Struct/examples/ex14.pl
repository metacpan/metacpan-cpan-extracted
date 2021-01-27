#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Utils qw(struct2snaks_array_ref);

my $struct_hr = {
        'snaks' => {
                'P31' => [{
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

                }],
                'P2534' => [{
                        'datatype' => 'math',
                        'datavalue' => {
                                'type' => 'string',
                                'value' => 'E = m c^2',
                        },
                        'property' => 'P2534',
                        'snaktype' => 'value',
                }],
        },
        'snaks-order' => [
                'P31',
                'P2534',
        ],
};

# Convert snaks structure to list of Snak objects.
my $snaks_ar = struct2snaks_array_ref($struct_hr, 'snaks');

# Print out. 
foreach my $snak (@{$snaks_ar}) {
        print 'Property: '.$snak->property."\n";
        print 'Type: '.$snak->datatype."\n";
        print 'Value: '.$snak->datavalue->value."\n";
        print "\n";
}

# Output:
# Property: P31
# Type: wikibase-item
# Value: Q5
#
# Property: P2534
# Type: math
# Value: E = m c^2
#