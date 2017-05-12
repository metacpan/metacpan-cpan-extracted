use strict;
use warnings;
use Test::More tests => 2;
use Text::XLogfile ':all';

my $xlogline = "foo=bar:baz=quux:deli=cious";

my $hash = {
    baz  => 'quux',
    deli => 'cious',
    foo  => 'bar',
};

my $h2x =  make_xlogline($hash);
my $x2h = parse_xlogline("$xlogline\n");

my @fields_x = sort split /:/, $xlogline;
my @fields_h = sort split /:/, $h2x;

is_deeply(\@fields_x, \@fields_h, "parse_xlogline chomps");
is_deeply($hash,      $x2h,       "parse_xlogline chomps");

