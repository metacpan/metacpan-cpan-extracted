#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value::Lexeme;
use Wikibase::Datatype::Value::Lexeme;

# Object.
my $obj = Wikibase::Datatype::Value::Lexeme->new(
        'value' => 'L42284',
);

# Print.
print Wikibase::Datatype::Print::Value::Lexeme::print($obj)."\n";

# Output:
# L42284