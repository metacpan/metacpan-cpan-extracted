#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::String;

# Object.
my $obj = Wikibase::Datatype::MediainfoStatement->new(
        'id' => 'M123$00C04D2A-49AF-40C2-9930-C551916887E8',

        # creator (P170)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'property' => 'P170',
                 'snaktype' => 'novalue',
        ),
        'property_snaks' => [
                # Wikimedia username (P4174): Lviatour
                Wikibase::Datatype::MediainfoSnak->new(
                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                 'value' => 'Lviatour',
                         ),
                         'property' => 'P4174',
                ),

                # URL (P2699): https://commons.wikimedia.org/wiki/user:Lviatour
                Wikibase::Datatype::MediainfoSnak->new(
                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                 'value' => 'https://commons.wikimedia.org/wiki/user:Lviatour',
                         ),
                         'property' => 'P2699',
                ),

                # author name string (P2093): Lviatour
                Wikibase::Datatype::MediainfoSnak->new(
                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                 'value' => 'Lviatour',
                         ),
                         'property' => 'P2093',
                ),

                # object has role (P3831): photographer (Q33231)
                Wikibase::Datatype::MediainfoSnak->new(
                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                 'value' => 'Q33231',
                         ),
                         'property' => 'P3831',
                ),
        ],
);

# Print out.
print 'Id: '.$obj->id."\n";
print 'Statement: '.$obj->snak->property.' -> ';
if ($obj->snak->snaktype eq 'value') {
        print $obj->snak->datavalue->value."\n";
} elsif ($obj->snak->snaktype eq 'novalue') {
        print "-\n";
} elsif ($obj->snak->snaktype eq 'somevalue') {
        print "?\n";
}
print "Qualifiers:\n";
foreach my $property_snak (@{$obj->property_snaks}) {
        print "\t".$property_snak->property.' -> '.
                $property_snak->datavalue->value."\n";
}
print 'Rank: '.$obj->rank."\n";

# Output:
# Id: M123$00C04D2A-49AF-40C2-9930-C551916887E8
# Statement: P170 -> -
# Qualifiers:
#         P4174 -> Lviatour
#         P2699 -> https://commons.wikimedia.org/wiki/user:Lviatour
#         P2093 -> Lviatour
#         P3831 -> Q33231
# Rank: normal