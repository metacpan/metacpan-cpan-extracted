use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('XML::API');
}

my $x = XML::API->new;
isa_ok( $x, 'XML::API' );

$x->_open('_open');
$x->_open('_ast');
$x->_element( '_comment', 'one' );
$x->_element( '_comment', 'two' );
$x->_close('_ast');
$x->_close('_open');

is(
    "$x", '<?xml version="1.0" encoding="UTF-8" ?>
<_open>
  <_ast>
    <_comment>one</_comment>
    <_comment>two</_comment>
  </_ast>
</_open>', 'oddball'
);

