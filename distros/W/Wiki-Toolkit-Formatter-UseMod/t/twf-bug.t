use strict;
use Test::More tests => 1;
use Wiki::Toolkit::Formatter::UseMod;

my $formatter = Wiki::Toolkit::Formatter::UseMod->new;

my $foo = "x";
$foo .= "" if $foo =~ /x/;

my $html = $formatter->format("test");
is( $html, "<p>test</p>\n", "Text::WikiFormat bug avoided" );
