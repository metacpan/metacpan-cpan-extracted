# -*- perl -*-
use strict;
use lib qw(t lib);
use Test::More;

BEGIN {
    plan(tests => 7);
    use_ok('Text::Locus');
};

my $loc = new Text::Locus;
$loc->add('foo', 10, 11, 12);
$loc->add('bar', 1);
ok($loc->has_file('foo'));
ok($loc->has_file('bar'));
ok(!$loc->has_file('baz'));
is(join(',',$loc->filenames), 'foo,bar');
is(join(',',$loc->filelines('foo')),'10,11,12');
ok($loc eq $loc->clone);
    
