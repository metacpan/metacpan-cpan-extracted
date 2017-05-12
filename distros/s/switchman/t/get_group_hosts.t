use strict;
use warnings;

use App::Switchman;
use Test::Deep;
use Test::More;

my $switchman = App::Switchman->new({
    command => 'dummy',
    lockname => 'dummy',
    prefix => '/dummy',
    zkhosts => 'localhost:2181',
});

my @tests = (
    [[{a => [qw/abc def/]}, 'a'], [qw/abc def/], 'plain groups'],
    [[{a => [qw/abc def/], b => 'a'}, 'b'], [qw/abc def/], 'nested groups'],
    [[{a => [qw/abc def/], b => 'a', c => 'b'}, 'c'], [qw/abc def/], 'deeply nested groups'],
    [[{a => [qw/abc def b/], b => 'a'}, 'a'], [qw/abc def/], 'cycles do not hang'],
);
for my $t (@tests) {
    cmp_bag($switchman->get_group_hosts(@{$t->[0]}), $t->[1], $t->[2]);
}

done_testing;
