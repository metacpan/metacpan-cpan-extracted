#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Form;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;

# Object.
my $obj = Wikibase::Datatype::Form->new(
        'grammatical_features' => [
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q123',
                ),
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q321',
                ),
        ],
        'id' => 'identifier',
        'representations' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => 'Text',
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'en',
                        'value' => 'Text',
                ),
        ],
        'statements' => [
                Wikibase::Datatype::Statement->new(
                        'snak' => Wikibase::Datatype::Snak->new(
                                'datatype' => 'wikibase-item',
                                'datavalue' => Wikibase::Datatype::Value::Item->new(
                                       'value' => 'Q1',
                                ),
                                'property' => 'P1',
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
# Id: identifier
# Number of grammatical features: 2
# Number of representations: 2
# Number of statements: 1