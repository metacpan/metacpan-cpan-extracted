#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(encode_utf8);
use Wikibase::Datatype::Print::Value::Quantity;
use Wikibase::Datatype::Value::Quantity;

# Object.
my $obj = Wikibase::Datatype::Value::Quantity->new(
        'lower_bound' => 9,
        'unit' => 'Q190900',
        'upper_bound' => 11,
        'value' => 10,
);

# Print.
print encode_utf8(Wikibase::Datatype::Print::Value::Quantity::print($obj))."\n";

# Output:
# 10±1 (Q190900)