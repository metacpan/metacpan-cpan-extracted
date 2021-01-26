#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Datatype::Mediainfo;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

# Object.
my $statement1 = Wikibase::Datatype::MediainfoStatement->new(
        # instance of (P31) human (Q5)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q5',
                ),
                'property' => 'P31',
        ),
        'property_snaks' => [
                # of (P642) alien (Q474741)
                Wikibase::Datatype::MediainfoSnak->new(
                        'datavalue' => Wikibase::Datatype::Value::Item->new(
                                'value' => 'Q474741',
                        ),
                        'property' => 'P642',
                ),
        ],
);
my $statement2 = Wikibase::Datatype::MediainfoStatement->new(
        # sex or gender (P21) male (Q6581097)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q6581097',
                ),
                'property' => 'P21',
        ),
);

# Main mediainfo.
my $obj = Wikibase::Datatype::Mediainfo->new(
        'id' => 'M16041229',
        'labels' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => decode_utf8('Pláž Papagayo, ostrov Lanzarote, Kanárské ostrovy, Španělsko'),
                ),
        ],
        'lastrevid' => 528085091,
        'modified' => '2021-01-24T11:44:10Z',
        'page_id' => 16041229,
        'statements' => [
                $statement1,
                $statement2,
        ],
        'title' => 'File:Lanzarote 1 Luc Viatour.jpg',
);

# Print out.
print "Title: ".$obj->title."\n";
print 'Id: '.$obj->id."\n";
print 'Page id: '.$obj->page_id."\n";
print 'Modified: '.$obj->modified."\n";
print 'Last revision id: '.$obj->lastrevid."\n";
print "Labels:\n";
foreach my $label (sort { $a->language cmp $b->language } @{$obj->labels}) {
        print "\t".encode_utf8($label->value).' ('.$label->language.")\n";
}
print "Statements:\n";
foreach my $statement (@{$obj->statements}) {
        print "\tStatement:\n";
        print "\t\t".$statement->snak->property.' -> '.$statement->snak->datavalue->value."\n";
        if (@{$statement->property_snaks}) {
                print "\t\tQualifers:\n";
                foreach my $property_snak (@{$statement->property_snaks}) {
                        print "\t\t\t".$property_snak->property.' -> '.
                                $property_snak->datavalue->value."\n";
                }
        }
}

# Output:
# Title: File:Lanzarote 1 Luc Viatour.jpg
# Id: M16041229
# Page id: 16041229
# Modified: 2021-01-24T11:44:10Z
# Last revision id: 528085091
# Labels:
#         Pláž Papagayo, ostrov Lanzarote, Kanárské ostrovy, Španělsko (cs)
# Statements:
#         Statement:
#                 P31 -> Q5
#                 Qualifers:
#                         P642 -> Q474741
#         Statement:
#                 P21 -> Q6581097