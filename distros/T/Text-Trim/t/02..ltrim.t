use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('Text::Trim');
}

my $text = my $orig = "\t  foo\t  \t\n";
my $expected = "foo\t  \t\n";
is(ltrim($text), $expected, 'ltrim in scalar context');
is($text, $orig, ".. didn't affect original");

ltrim($text);
is($text, $expected, 'ltrim in place changes original');

{
    local $_ = $orig;
    my $ltrimmed = ltrim;
    is($ltrimmed, $expected, '$scalar = ltrim() works on $_');
    is($_,     , $orig, ".. didn't affect original");

    ltrim;
    is($_,     , $expected, "ltrim() alters \$_")
}

my @before = (
    "  foo  ",
    "\tbar\t",
    "\nbaz\n",
);
my @expected = ("foo  ", "bar\t", "baz\n");
my @ltrimmed = ltrim @before;
is_deeply(\@ltrimmed, \@expected, 'ltrim on a list in list content');
ltrim @before;
is_deeply(\@before, \@expected,  'ltrim on a list in place');

$expected = "@expected";
my $ltrimmed = ltrim @before;
is($ltrimmed, $expected, 'ltrim on a list in scalar context');

__END__

vim: ft=perl ts=8 sts=4 sw=4 sr et
