use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'need XML::LibXML' unless eval { require XML::LibXML };
    plan skip_all => 'need CSS::Tiny' unless eval { require CSS::Tiny }
}

BEGIN { plan tests => 3 };

use Text::EmacsColor::Result;

my $_style = 'i { font-family: "OhHai Sans" }';
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

my $css = $r->css;
isa_ok $css, 'CSS::Tiny';

is $css->{i}{'font-family'}, '"OhHai Sans"';

