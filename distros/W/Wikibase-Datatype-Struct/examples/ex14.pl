#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::MediainfoStatement qw(struct2obj);

# Item structure.
my $struct_hr = {
        'id' => 'M123$00C04D2A-49AF-40C2-9930-C551916887E8',
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
                                },
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
};

# Get object.
my $obj = struct2obj($struct_hr);

# Print out.
print 'Id: '.$obj->id."\n";
print 'Statements: '.$obj->snak->property.' -> '.$obj->snak->datavalue->value."\n";
print "Qualifiers:\n";
foreach my $property_snak (@{$obj->property_snaks}) {
        print "\t".$property_snak->property.' -> '.
                $property_snak->datavalue->value."\n";
}
print 'Rank: '.$obj->rank."\n";

# Output:
# Id: M123$00C04D2A-49AF-40C2-9930-C551916887E8
# Statements: P31 -> Q5
# Qualifiers:
#         P642 -> Q474741
# Rank: normal