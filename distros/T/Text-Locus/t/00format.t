# -*- perl -*-
use strict;
use lib qw(t lib);
use Test::More;

BEGIN {
    plan(tests => 4);
    use_ok('Text::Locus');
};

my $loc = new Text::Locus;
is($loc->format,'','empty format');
is($loc->format('test', 'message'), 'test message', 'empty format (prefixed)');

$loc = new Text::Locus("foo", 10, 15);
is("$loc", "foo:10,15", 'compound locus');


