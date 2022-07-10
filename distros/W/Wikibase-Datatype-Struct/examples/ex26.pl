#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Statement qw(struct2obj);

# Item structure.
my $struct_hr = {
        'id' => 'Q123$00C04D2A-49AF-40C2-9930-C551916887E8',
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
        'qualifiers' => {
                'P642' => [{
                        'datatype' => 'wikibase-item',
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
        'references' => [{
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
        }],
        'type' => 'statement',
};

# Get object.
my $obj = struct2obj($struct_hr);

# Print out.
print 'Id: '.$obj->id."\n";
print 'Claim: '.$obj->snak->property.' -> '.$obj->snak->datavalue->value."\n";
print "Qualifiers:\n";
foreach my $property_snak (@{$obj->property_snaks}) {
        print "\t".$property_snak->property.' -> '.
                $property_snak->datavalue->value."\n";
}
print "References:\n";
foreach my $reference (@{$obj->references}) {
        print "\tReference:\n";
        foreach my $reference_snak (@{$reference->snaks}) {
                print "\t\t".$reference_snak->property.' -> '.
                        $reference_snak->datavalue->value."\n";
        }
}
print 'Rank: '.$obj->rank."\n";

# Output:
# Id: Q123$00C04D2A-49AF-40C2-9930-C551916887E8
# Claim: P31 -> Q5
# Qualifiers:
#         P642 -> Q474741
# References:
#         Reference:
#                 P248 -> Q53919
#                 P214 -> 113230702
#                 P813 -> +2013-12-07T00:00:00Z
# Rank: normal