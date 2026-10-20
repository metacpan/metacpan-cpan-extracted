#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use_ok('Time::Keeper::Sun') or BAIL_OUT('Time::Keeper::Sun does not load');

ok(defined $Time::Keeper::Sun::VERSION, 'it has a version');
like($Time::Keeper::Sun::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

ok(!$INC{'Time/Keeper.pm'}, 'loading it does not load Time::Keeper');
is(Time::Keeper::Sun::_tk_abi_resolved(), 0, 'nor look for its table');

cmp_ok(Time::Keeper::Sun::_tk_abi_built(), '>=', 1,
       'it was compiled against a version of Time::Keeper\'s table');
cmp_ok(Time::Keeper::Sun::_tk_abi_header(), '>=', Time::Keeper::Sun::_tk_abi_built(),
       'and the header it saw is that version or a later one');

{
    local $@ = 'left alone';
    my $found = Time::Keeper::Sun::_tk_abi_version();
    is($@, 'left alone', 'finding the table leaves the caller\'s $@ alone');
    ok($INC{'Time/Keeper.pm'}, 'asking for the table loads Time::Keeper');
    cmp_ok($found, '>=', Time::Keeper::Sun::_tk_abi_built(),
           'and the table found is the version built against or a later one');
    is($found, Time::Keeper::_abi_version(), 'which is the table Time::Keeper says it has');
}

is(Time::Keeper::Sun::_tk_abi_resolved(), 1, 'the table is kept once found');

{
    my ($sec, $nsec) = Time::Keeper::Sun::_tk_now();
    my $now = time;
    cmp_ok(abs($sec - $now), '<=', 2, 'a call through the table reaches Time::Keeper\'s clock');
    cmp_ok($nsec, '>=', 0, 'with nanoseconds');
    cmp_ok($nsec, '<', 1_000_000_000, 'in range');
}

diag("Testing Time::Keeper::Sun $Time::Keeper::Sun::VERSION on Time::Keeper $Time::Keeper::VERSION (table version ${\ Time::Keeper::_abi_version() }), Perl $], $^X");

done_testing;
