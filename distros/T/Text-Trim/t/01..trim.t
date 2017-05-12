use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('Text::Trim');
}

my $text = my $orig = "\t  foo\t  \t\n";
is(trim($text), 'foo', 'trim in scalar context');
is($text, $orig, ".. didn't affect original");

trim($text);
is($text, 'foo', 'trim in place changes original');

{
    local $_ = $orig;
    my $trimmed = trim;
    is($trimmed, 'foo', '$scalar = trim() works on $_');
    is($_,     , $orig, ".. didn't affect original");

    trim;
    is($_,     , 'foo', "trim() alters \$_")
}

my @before = (
    "  foo  ",
    "\tbar\t",
    "\nbaz\n",
);
my @expected = qw( foo bar baz );
my @trimmed = trim @before;
is_deeply(\@trimmed, \@expected, 'trim on a list in list content');
trim @before;
is_deeply(\@before, \@expected,  'trim on a list in place');

my $expected = "@expected";
my $trimmed = trim @before;
is($trimmed, $expected, 'trim on a list in scalar context');

__END__

vim: ft=perl ts=8 sts=4 sw=4 sr et
