#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Cache;
use Wikibase::Cache::Backend::Basic;
use Wikibase::Datatype::Mediainfo;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Print::Mediainfo;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

# Statements.
my $statement1 = Wikibase::Datatype::MediainfoStatement->new(
        # depicts (P180) beach (Q40080)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q40080',
                ),
                'property' => 'P180',
        ),
);
my $statement2 = Wikibase::Datatype::MediainfoStatement->new(
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
my $statement3 = Wikibase::Datatype::MediainfoStatement->new(
        # copyright status (P6216) copyrighted (Q50423863)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q50423863',
                ),
                'property' => 'P6216',
        ),
);
my $statement4 = Wikibase::Datatype::MediainfoStatement->new(
        # copyright license (P275) Creative Commons Attribution-ShareAlike 3.0 Unported (Q14946043)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q14946043',
                ),
                'property' => 'P275',
        ),
);
my $statement5 = Wikibase::Datatype::MediainfoStatement->new(
        # Commons quality assessment (P6731) Wikimedia Commons featured picture (Q63348049)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q63348049',
                ),
                'property' => 'P6731',
        ),
);
my $statement6 = Wikibase::Datatype::MediainfoStatement->new(
        # inception (P571) 16. 7. 2011
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                'datavalue' => Wikibase::Datatype::Value::Time->new(
                        'value' => '+2011-07-16T00:00:00Z',
                ),
                'property' => 'P571',
        ),
);
my $statement7 = Wikibase::Datatype::MediainfoStatement->new(
        # source of file (P7482) original creation by uploader (Q66458942)
        'snak' => Wikibase::Datatype::MediainfoSnak->new(
                'datavalue' => Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q66458942',
                ),
                'property' => 'P7482',
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
                $statement3,
                $statement4,
                $statement5,
                $statement6,
                $statement7,
        ],
        'title' => 'File:Lanzarote 1 Luc Viatour.jpg',
);

# Cache.
my $cache = Wikibase::Cache->new(
        'backend' => 'Basic',
);

# Print.
print Wikibase::Datatype::Print::Mediainfo::print($obj, {
        'cache' => $cache,
})."\n";

# Output:
# Id: M16041229
# Title: File:Lanzarote 1 Luc Viatour.jpg
# NS: 6
# Last revision id: 528085091
# Date of modification: 2021-01-24T11:44:10Z
# Page ID: 16041229
# Statements:
#   P180 (depicts): Q40080 (normal)
#   P170: no value (normal)
#    P4174: Lviatour
#    P2699: https://commons.wikimedia.org/wiki/user:Lviatour
#    P2093: Lviatour
#    P3831: Q33231
#   P6216: Q50423863 (normal)
#   P275: Q14946043 (normal)
#   P6731: Q63348049 (normal)
#   P571: 16 July 2011 (Q1985727) (normal)
#   P7482: Q66458942 (normal)