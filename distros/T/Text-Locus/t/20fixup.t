# -*- perl -*-
use strict;
use lib qw(t lib);
use Test::More;

BEGIN {
    plan(tests => 5);
    use_ok('Text::Locus');
};

my $loc = new Text::Locus;

my $loc = new Text::Locus;
$loc->add('foo', 10, 11, 12, 13);
$loc->add('foo', 24, 28);
$loc->add('bar', 1, 5);
$loc->add('baz', 8, 9);
is($loc->format, "foo:10-13,24,28;bar:1,5;baz:8-9", 'initial');

$loc->fixup_names('foo' => 'Foo', 'bar' => 'BAR');
is($loc->format, "Foo:10-13,24,28;BAR:1,5;baz:8-9",'change names');

$loc->fixup_lines('Foo' => -1, 'baz' => 2);
is($loc->format, "Foo:9-12,23,27;BAR:1,5;baz:10-11", 'offset');

$loc->fixup_lines(3);
is($loc->format, "Foo:12-15,26,30;BAR:4,8;baz:13-14", 'global offset');
