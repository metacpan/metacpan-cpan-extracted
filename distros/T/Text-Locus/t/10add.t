# -*- perl -*-
use strict;
use lib qw(t lib);
use Test::More;

BEGIN {
    plan(tests => 6);
    use_ok('Text::Locus');
};

my $loc = new Text::Locus;
$loc->add('foo', 10);
is($loc->format, "foo:10", 'initial addition');

$loc->add('foo', 11);
$loc->add('foo', 12);
$loc->add('foo', 13);
is($loc->format, "foo:10-13", 'adjacent lines');

$loc->add('foo', 24);
$loc->add('foo', 28);
is($loc->format, "foo:10-13,24,28", 'non-adjacent lines');
is($loc->format('test', 'message'), "foo:10-13,24,28: test message",
                'non-adjacent lines (prefixed)');

$loc->add('bar', 1);
$loc->add('baz', 8);
$loc->add('baz', 9);
$loc->add('bar', 5);
is($loc->format, "foo:10-13,24,28;bar:1,5;baz:8-9", 'distinct source names');

