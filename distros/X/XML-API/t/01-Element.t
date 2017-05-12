use strict;
use warnings;
use Test::More tests => 11;

BEGIN {
    use_ok('XML::API');
}

can_ok(
    'XML::API::Element', qw(
      new
      add
      )
);

my $e = XML::API::Element->new( element => 'e', );
isa_ok( $e, 'XML::API::Element' );
is( $e->as_string, '<e />', 'single tag' );

$e->add('content');
is( $e->as_string, '<e>content</e>', 'single tag with content' );

my $c = XML::API::Element->new( comment => 'comment --', );
isa_ok( $c, 'XML::API::Element' );
is( $c->as_string, '<!-- comment - - -->', 'comment' );

my $cdata = XML::API::Element->new( cdata => 'cdata', );
isa_ok( $cdata, 'XML::API::Element' );
is( $cdata->as_string, '<![CDATA[cdata]]>', 'cdata' );

my $c1 = XML::API::Element->new( element => 'c1', );
$c1->add('cn1');

$e->add($c1);

is(
    $e->as_string( '', '  ' ),
    '<e>content
  <c1>cn1</c1>
</e>', 'combined'
);

is(
    $e->as_string( '', '' ),
    '<e>content
<c1>cn1</c1>
</e>', 'combined no indent'
);

