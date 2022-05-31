#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Monolingual;

# Object.
my $obj = Wikibase::Datatype::Form->new(
        'grammatical_features' => [
                # singular
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q110786',
                ),
                # nominative case
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q131105',
                ),
        ],
        'id' => 'L469-F1',
        'representations' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => 'pes',
                ),
        ],
        'statements' => [
                Wikibase::Datatype::Statement->new(
                        'snak' => Wikibase::Datatype::Snak->new(
                                'datatype' => 'string',
                                'datavalue' => Wikibase::Datatype::Value::String->new(
                                       'value' => decode_utf8('pɛs'),
                                ),
                                'property' => 'P898',
                        ),
                ),
        ],
);

# Get id.
my $id = $obj->id;

# Get counts.
my $gr_count = @{$obj->grammatical_features};
my $re_count = @{$obj->representations};
my $st_count = @{$obj->statements};

# Print out.
print "Id: $id\n";
print "Number of grammatical features: $gr_count\n";
print "Number of representations: $re_count\n";
print "Number of statements: $st_count\n";

# Output:
# Id: L469-F1
# Number of grammatical features: 2
# Number of representations: 1
# Number of statements: 1