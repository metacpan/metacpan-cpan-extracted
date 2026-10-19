#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;

# The C ABI: the table has a stable address and version, and the self-test
# calls every entry through that address, as another extension would, with
# every answer checked. The value it makes is one Perl can use.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $p = Time::Keeper::_abi_ptr();
ok($p, '_abi_ptr gives an address');
is($p, Time::Keeper::_abi_ptr(), 'the same one every call');
like($p, qr/^\d+$/, 'as an unsigned integer');
is(Time::Keeper::_abi_version(), 2, 'the table is version 2');

my ($step, $t) = Time::Keeper::_abi_selftest($p);
is($step, 0, 'every entry answered as the header says')
    or diag("check $step in include/tk/tk_abi_selftest.h failed");
SKIP: {
    skip 'the self-test did not finish', 6 if $step;
    isa_ok($t, 'Time::Keeper', 'the value C made');
    is($t->rfc9557, '2025-10-09T17:53:20.250+09:00[Asia/Tokyo]', 'with the instant and zone C gave it');
    is($t->locale, 'fr', 'and the locale');
    is($t->format_date('full'), 'jeudi 9 octobre 2025', 'and Perl can use it');
    is($t->plus(days => 1)->day, 10, 'as any value');
    is(Time::Keeper->compare($t, Time::Keeper->from_epoch('1760000000.25')), 0, 'the same instant as Perl makes');
}
for (1 .. 200) { my ($s) = Time::Keeper::_abi_selftest($p); }
is((Time::Keeper::_abi_selftest($p))[0], 0, 'and again after two hundred runs');
{
    local $@ = 'left alone';
    Time::Keeper::_abi_selftest($p);
    is($@, 'left alone', 'parse through the table leaves $@ as it was');
}

done_testing;
