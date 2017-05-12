use strict;
use warnings;
use utf8;
use Test::More;
use Data::Section::TestBase;

my @blocks = blocks;

is(0+@blocks, 3);

subtest 'first block' => sub {
    my $b = $blocks[0];
    is($b->name, 'foo');
    is($b->get_section('input'), 'yyy');
    is($b->get_section('expected'), 'zzz');
    is($b->get_lineno, 47, 'lineno');
};

subtest 'second block' => sub {
    my $b = $blocks[1];
    is($b->name, 'bar');
    is($b->get_section('input'), "xxx\n");
    is($b->get_section('expected'), "ppp\n\n");
    is($b->get_lineno, 51, 'lineno');
};

test_third_block($blocks[2], 'third block');

@blocks = blocks('foo');
is(0+blocks('foo'),  1);
test_third_block($blocks[0], 'first filtered block');

done_testing;

sub test_third_block {
    my ($b, $name) = @_;
    subtest $name => sub {
        is($b->name, 'baz');
        is($b->get_section('foo'), "vvv");
        is($b->get_section('bar'), "www");
        is($b->get_lineno, 57, 'lineno');
    };
}

__DATA__

=== foo
--- input: yyy
--- expected: zzz

=== bar
--- input
xxx
--- expected
ppp

=== baz
--- foo : vvv
--- bar: www
