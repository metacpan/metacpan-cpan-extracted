#! /usr/local/bin/perl -w

# vim: syntax=perl
# vim: tabstop=4

use strict;

use Test;

use constant NUM_TESTS => 4;

use Locale::Util qw (parse_http_accept_language parse_http_accept_charset);

BEGIN {
	plan tests => NUM_TESTS;
}

my ($string, @items, $items);

$string = "baz; q=0.1, foo, bar; q=0.7";
@items = parse_http_accept_language $string;
$items = join '|', @items;
ok $items, "foo|bar|baz";

# Illegal language identifiers should be filtered out.
$string = "baz; q=0.1, illegal4this, foo, bar; q=0.7";
@items = parse_http_accept_language $string;
$items = join '|', @items;
ok $items, "foo|bar|baz";

# The catch-all language is C.
$string = "baz; q=0.1, *; q=0.05, foo, bar; q=0.7";
@items = parse_http_accept_language $string;
$items = join '|', @items;
ok $items, "foo|bar|baz|C";

$string = "baz; q=0.1, foo, bar; q=0.7";
@items = parse_http_accept_charset $string;
$items = join '|', @items;
ok $items, "foo|bar|baz";

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:
