#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value::Monolingual;
use Wikibase::Datatype::Value::Monolingual;

# Object.
my $obj = Wikibase::Datatype::Value::Monolingual->new(
        'language' => 'en',
        'value' => 'English text',
);

# Print.
print Wikibase::Datatype::Print::Value::Monolingual::print($obj)."\n";

# Output:
# English text (en)