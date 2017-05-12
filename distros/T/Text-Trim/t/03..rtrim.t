use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('Text::Trim');
}

my $text = my $orig = "\t  foo\t  \t\n";
my $expected = "\t  foo";
is(rtrim($text), $expected, 'rtrim in scalar context');
is($text, $orig, ".. didn't affect original");

rtrim($text);
is($text, $expected, 'rtrim in place changes original');

{
    local $_ = $orig;
    my $rtrimmed = rtrim;
    is($rtrimmed, $expected, '$scalar = rtrim() works on $_');
    is($_,     , $orig, ".. didn't affect original");

    rtrim;
    is($_,     , $expected, "rtrim() alters \$_")
}

my @before = (
    "  foo  ",
    "\tbar\t",
    "\nbaz\n",
);
my @expected = ("  foo", "\tbar", "\nbaz");
my @rtrimmed = rtrim @before;
is_deeply(\@rtrimmed, \@expected, 'rtrim on a list in list content');
rtrim @before;
is_deeply(\@before, \@expected,  'rtrim on a list in place');

$expected = "@expected";
my $rtrimmed = rtrim @before;
is($rtrimmed, $expected, 'rtrim on a list in scalar context');

__END__

vim: ft=perl ts=8 sts=4 sw=4 sr et
