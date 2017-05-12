use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use Devel::Hide qw(XML::LibXML CSS::Tiny);

use ok 'Text::EmacsColor::Result';

my $res;
lives_ok {
    $res = Text::EmacsColor::Result->new( full_html => 'foo' );
} 'no errors';

ok $res, 'got object';

throws_ok {
    $res->html_dom
} qr/you must install xml::libxml/i;

throws_ok {
    $res->css
} qr/you must install css::tiny/i;
