#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Datatype::Print::Sense;
use Wikibase::Datatype::Sense;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::String;

# One sense for Czech noun 'pes'.
# https://www.wikidata.org/wiki/Lexeme:L469

# Statements.
my $statement_item = Wikibase::Datatype::Statement->new(
        # item for this sense (P5137) dog (Q144)
        'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q144',
                 ),
                 'property' => 'P5137',
        ),
);
my $statement_image = Wikibase::Datatype::Statement->new(
        # image (P5137) 'Canadian Inuit Dog.jpg'
        'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'commonsMedia',
                 'datavalue' => Wikibase::Datatype::Value::String->new(
                         'value' => 'Canadian Inuit Dog.jpg',
                 ),
                 'property' => 'P18',
        ),
);

# Object.
my $obj = Wikibase::Datatype::Sense->new(
        'glosses' => [
                Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'domesticated mammal related to the wolf',
                ),
                Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('psovitá šelma chovaná jako domácí zvíře'),
                ),
        ],
        'id' => 'ID',
        'statements' => [
                $statement_item,
                $statement_image,
        ],
);

# Print.
print encode_utf8(scalar Wikibase::Datatype::Print::Sense::print($obj))."\n";

# Output:
# Id: ID
# Glosses:
#   domesticated mammal related to the wolf (en)
#   psovitá šelma chovaná jako domácí zvíře (cs)
# Statements:
#   P5137: Q144 (normal)
#   P18: Canadian Inuit Dog.jpg (normal)