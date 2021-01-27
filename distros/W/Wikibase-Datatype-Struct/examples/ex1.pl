#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Mediainfo;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Struct::Mediainfo qw(obj2struct);
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;

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

# Main item.
my $obj = Wikibase::Datatype::Mediainfo->new(
        'id' => 'Q42',
        'labels' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => 'Douglas Adams',
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'en',
                        'value' => 'Douglas Adams',
                ),
        ],
        'page_id' => 123,
        'statements' => [
                $statement1,
                $statement2,
        ],
        'title' => 'Q42',
);

# Get structure.
my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

# Dump to output.
p $struct_hr;

# Output:
# TODO