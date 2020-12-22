#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Sense;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;

# Statement.
my $statement = Wikibase::Datatype::Statement->new(
        # instance of (P31) human (Q5)
        'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q5',
                 ),
                 'property' => 'P31',
        ),
);

# Object.
my $obj = Wikibase::Datatype::Sense->new(
        'glosses' => [
                Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Glosse en',
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Glosse cs',
                ),
        ],
        'id' => 'ID',
        'statements' => [
                $statement,
        ],
);

# Get id.
my $id = $obj->id;

# Get glosses.
my @glosses = map { $_->value.' ('.$_->language.')' } @{$obj->glosses};

# Get statements.
my $statements_count = @{$obj->statements};

# Print out.
print "Id: $id\n";
print "Glosses:\n";
map { print "\t$_\n"; } @glosses;
print "Number of statements: $statements_count\n";

# Output:
# Id: ID
# Glosses:
#         Glosse en (en)
#         Glosse cs (cs)
# Number of statements: 1