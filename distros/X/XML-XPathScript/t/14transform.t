use strict;
use warnings;

use Test::More tests => 5;                      # last test to print

use XML::XPathScript;

my $xps = XML::XPathScript->new;

my $result = $xps->transform( '<doc>hello</doc>', 'fluff' );

is $result => 'fluff', '$xps->transform()';

$result = $xps->transform( '<doc><t>hello</t></doc>', '<%~ /doc/t %>' );
is $result => '<t>hello</t>' ;

# same stylesheet, different xml
$result = $xps->transform( '<doc><t>world!</t></doc>', undef );
is $result => '<t>world!</t>' ;

# same stylesheet, different xml
$result = $xps->transform( '<doc><t>foo</t></doc>' );
is $result => '<t>foo</t>' ;

# same xml document, different stylesheet
$result = $xps->transform( undef, '<%~ / %>' );
is $result => '<doc><t>foo</t></doc>' ;
