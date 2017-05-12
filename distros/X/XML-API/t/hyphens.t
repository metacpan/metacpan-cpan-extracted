use strict;
use warnings;
use Test::More tests => 1;
use XML::API;

my $x = XML::API->new;

$x->_ast(
    foo => [
        bar => '--'
    ]
);

is(
    $x->_as_string, '<?xml version="1.0" encoding="UTF-8" ?>
<foo>
  <bar>--</bar>
</foo>', 'double hyphen'
);

