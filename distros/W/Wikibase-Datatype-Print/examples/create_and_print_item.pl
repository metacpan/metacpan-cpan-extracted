#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Print::Item;
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

# Print.
print encode_utf8(scalar Wikibase::Datatype::Print::Item::print($obj))."\n";

# Output:
# Label: Douglas Adams (en)
# Description: English writer and humorist (en)
# Aliases:
#   Douglas Noel Adams (en)
#   Douglas Noël Adams (en)
#   Douglas N. Adams (en)
# Sitelinks:
#   Douglas Adams (cswiki)
#   Douglas Adams (enwiki)
# Statements:
#   P31: Q5 (normal)
#    P642: Q474741
#   References:
#     {
#       P248: Q53919
#       P214: 113230702
#       P813: 7 December 2013 (Q1985727)
#     }
#   P21: Q6581097 (normal)
#   References:
#     {
#       P248: Q53919
#       P214: 113230702
#       P813: 7 December 2013 (Q1985727)
#     }