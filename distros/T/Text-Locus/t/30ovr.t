# -*- perl -*-
use strict;
use lib qw(t lib);
use Test::More;

BEGIN {
    plan(tests => 4);
    use_ok('Text::Locus');
};

my $loc = new Text::Locus("foo", 10, 15);
is("$loc", "foo:10,15", 'overload ""');

$loc += "bar:11";
is("$loc", "foo:10,15;bar:11", 'increment');

$loc = new Text::Locus("foo", 10);
my $res = "bar:1" + $loc;
is("$res", "bar:1;foo:10", 'addition');
