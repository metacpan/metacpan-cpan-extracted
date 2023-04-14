#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value::Globecoordinate;
use Wikibase::Datatype::Value::Globecoordinate;

# Object.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
        'value' => [49.6398383, 18.1484031],
);

# Print.
print Wikibase::Datatype::Print::Value::Globecoordinate::print($obj)."\n";

# Output:
# (49.6398383, 18.1484031)