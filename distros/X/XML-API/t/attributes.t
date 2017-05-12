use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
    use_ok('XML::API');
}

my $x = XML::API->new;
$x->html_open( -class => 'pretty-style' );
is_deeply $x->_attrs, { class => 'pretty-style' }, 'pretty style';

$x->div_open;
$x->_attrs( { id => 'main-content' } );
is_deeply $x->_attrs, { id => 'main-content' }, 'main content', $x->div_close;

isa_ok $x->root_attrs, 'HASH';
isa_ok $x->root_attrs->{contents}, 'ARRAY';
isa_ok $x->root_attrs->{attrs},    'HASH';
isa_ok $x->root_attrs->{parent},   'XML::API::Element';

$x->div_open;
$x->_attrs( { id => 'inner-content', class => 'nice-content' } );
is_deeply $x->_attrs, { id => 'inner-content', class => 'nice-content' },
  'mixed';
$x->div_close;
