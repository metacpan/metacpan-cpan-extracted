#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Term;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

# Statements.
my $statement1 = Wikibase::Datatype::Statement->new(
        # instance of (P31) human (Q5)
        'snak' => Wikibase::Datatype::Snak->new(
                'datatype' => 'wikibase-item',
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q5',
                ),
                'property' => 'P31',
        ),
        'property_snaks' => [
                # of (P642) alien (Q474741)
                Wikibase::Datatype::Snak->new(
                        'datatype' => 'wikibase-item',
                        'datavalue' => Wikibase::Datatype::Value::Item->new(
                                'value' => 'Q474741',
                        ),
                        'property' => 'P642',
                ),
        ],
        'references' => [
                Wikibase::Datatype::Reference->new(
                        'snaks' => [
                                # stated in (P248) Virtual International Authority File (Q53919)
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'wikibase-item',
                                        'datavalue' => Wikibase::Datatype::Value::Item->new(
                                                'value' => 'Q53919',
                                        ),
                                        'property' => 'P248',
                                ),

                                # VIAF ID (P214) 113230702
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'external-id',
                                        'datavalue' => Wikibase::Datatype::Value::String->new(
                                                'value' => '113230702',
                                        ),
                                        'property' => 'P214',
                                ),

                                # retrieved (P813) 7 December 2013
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'time',
                                        'datavalue' => Wikibase::Datatype::Value::Time->new(
                                                'value' => '+2013-12-07T00:00:00Z',
                                        ),
                                        'property' => 'P813',
                                ),
                        ],
                ),
        ],
);
my $statement2 = Wikibase::Datatype::Statement->new(
        # sex or gender (P21) male (Q6581097)
        'snak' => Wikibase::Datatype::Snak->new(
                'datatype' => 'wikibase-item',
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q6581097',
                ),
                'property' => 'P21',
        ),
        'references' => [
                Wikibase::Datatype::Reference->new(
                        'snaks' => [
                                # stated in (P248) Virtual International Authority File (Q53919)
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'wikibase-item',
                                        'datavalue' => Wikibase::Datatype::Value::Item->new(
                                                'value' => 'Q53919',
                                        ),
                                        'property' => 'P248',
                                ),

                                # VIAF ID (P214) 113230702
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'external-id',
                                        'datavalue' => Wikibase::Datatype::Value::String->new(
                                                'value' => '113230702',
                                        ),
                                        'property' => 'P214',
                                ),

                                # retrieved (P813) 7 December 2013
                                Wikibase::Datatype::Snak->new(
                                        'datatype' => 'time',
                                        'datavalue' => Wikibase::Datatype::Value::Time->new(
                                                'value' => '+2013-12-07T00:00:00Z',
                                        ),
                                        'property' => 'P813',
                                ),
                        ],
                ),
        ],
);

# Main item.
my $obj = Wikibase::Datatype::Item->new(
        'aliases' => [
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => decode_utf8('Douglas Noël Adams'),
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => 'Douglas Noel Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => 'Douglas N. Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => 'Douglas Noel Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => decode_utf8('Douglas Noël Adams'),
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => 'Douglas N. Adams',
                ),
        ],
        'descriptions' => [
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => decode_utf8('anglický spisovatel, humorista a dramatik'),
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => 'English writer and humorist',
                ),
        ],
        'id' => 'Q42',
        'labels' => [
                Wikibase::Datatype::Term->new(
                        'language' => 'cs',
                        'value' => 'Douglas Adams',
                ),
                Wikibase::Datatype::Term->new(
                        'language' => 'en',
                        'value' => 'Douglas Adams',
                ),
        ],
        'page_id' => 123,
        'sitelinks' => [
                Wikibase::Datatype::Sitelink->new(
                        'site' => 'cswiki',
                        'title' => 'Douglas Adams',
                ),
                Wikibase::Datatype::Sitelink->new(
                        'site' => 'enwiki',
                        'title' => 'Douglas Adams',
                ),
        ],
        'statements' => [
                $statement1,
                $statement2,
        ],
        'title' => 'Q42',
);

# Print out.
print "Title: ".$obj->title."\n";
print 'Id: '.$obj->id."\n";
print 'Page id: '.$obj->page_id."\n";
print "Labels:\n";
foreach my $label (sort { $a->language cmp $b->language } @{$obj->labels}) {
        print "\t".encode_utf8($label->value).' ('.$label->language.")\n";
}
print "Descriptions:\n";
foreach my $desc (sort { $a->language cmp $b->language } @{$obj->descriptions}) {
        print "\t".encode_utf8($desc->value).' ('.$desc->language.")\n";
}
print "Aliases:\n";
foreach my $alias (sort { $a->language cmp $b->language } @{$obj->aliases}) {
        print "\t".encode_utf8($alias->value).' ('.$alias->language.")\n";
}
print "Sitelinks:\n";
foreach my $sitelink (@{$obj->sitelinks}) {
        print "\t".$sitelink->title.' ('.$sitelink->site.")\n";
}
print "Statements:\n";
foreach my $statement (@{$obj->statements}) {
        print "\tStatement:\n";
        print "\t\t".$statement->snak->property.' -> '.$statement->snak->datavalue->value."\n";
        print "\t\tQualifers:\n";
        foreach my $property_snak (@{$statement->property_snaks}) {
                print "\t\t\t".$property_snak->property.' -> '.
                        $property_snak->datavalue->value."\n";
        }
        print "\t\tReferences:\n";
        foreach my $reference (@{$statement->references}) {
                print "\t\t\tReference:\n";
                foreach my $reference_snak (@{$reference->snaks}) {
                        print "\t\t\t".$reference_snak->property.' -> '.
                                $reference_snak->datavalue->value."\n";
                }
        }
}

# Output:
# Title: Q42
# Id: Q42
# Page id: 123
# Labels:
#         Douglas Adams (cs)
#         Douglas Adams (en)
# Descriptions:
#         anglický spisovatel, humorista a dramatik (cs)
#         English writer and humorist (en)
# Aliases:
#         Douglas Noël Adams (cs)
#         Douglas Noel Adams (cs)
#         Douglas N. Adams (cs)
#         Douglas Noel Adams (en)
#         Douglas Noël Adams (en)
#         Douglas N. Adams (en)
# Sitelinks:
#         Douglas Adams (cswiki)
#         Douglas Adams (enwiki)
# Statements:
#         Statement:
#                 P31 -> Q5
#                 Qualifers:
#                         P642 -> Q474741
#                 References:
#                         Reference:
#                         P248 -> Q53919
#                         P214 -> 113230702
#                         P813 -> +2013-12-07T00:00:00Z
#         Statement:
#                 P21 -> Q6581097
#                 Qualifers:
#                 References:
#                         Reference:
#                         P248 -> Q53919
#                         P214 -> 113230702
#                         P813 -> +2013-12-07T00:00:00Z