use strict;
use warnings;
use Test::More;

BEGIN { plan skip_all => 'need XML::LibXML' unless eval { require XML::LibXML } }
BEGIN { plan tests => 3 };

use Text::EmacsColor::Result;

my $_style = 'style goes here';
my $r = Text::EmacsColor::Result->new( full_html => qq{
<html>
<head>
<style>$_style</style>
</head>
<body>
Here is a <i>some text</i>.
</body>
</html>
});

ok $r;

my $dom = $r->html_dom;
isa_ok $dom, 'XML::LibXML::Document';

my $style = $r->_extract_style;
is $style, $_style;
