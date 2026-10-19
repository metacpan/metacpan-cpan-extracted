#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The module loads, carries a plain version, resolved Time::Keeper's table at
# load and leaves Time::Keeper::Zone alone until a named zone is wanted.

ok(!$INC{'Time/Keeper/Zone.pm'}, 'before the load, Time::Keeper::Zone is not loaded');
use_ok('Time::Keeper::Recurrence') or BAIL_OUT('Time::Keeper::Recurrence does not load');

ok(defined $Time::Keeper::Recurrence::VERSION, 'it has a version');
like($Time::Keeper::Recurrence::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

ok($INC{'Time/Keeper.pm'}, 'loading it loaded Time::Keeper');
ok(!$INC{'Time/Keeper/Zone.pm'}, 'and not Time::Keeper::Zone: that waits for a named zone');

can_ok('Time::Keeper::Recurrence', '_tk_abi_version');
is(Time::Keeper::Recurrence::_tk_abi_version(), Time::Keeper::_abi_version(),
   'the Time::Keeper table it resolved reports the version Time::Keeper reports');
cmp_ok(Time::Keeper::Recurrence::_tk_abi_version(), '>=', Time::Keeper::Recurrence::_tk_abi_needed(),
   'which is at least the version it was built to call');

$@ = "left alone";
my @v = Time::Keeper::Recurrence->abi_versions;
is($@, "left alone", "resolving the zone table leaves $@ as it was");
is(scalar @v, 2, 'abi_versions gives two versions');
ok($INC{'Time/Keeper/Zone.pm'}, 'and asking for them loaded Time::Keeper::Zone');
is($v[1], Time::Keeper::Zone::_abi_version(), 'the Zone table it resolved reports the version Zone reports');
cmp_ok($v[1], '>=', Time::Keeper::Recurrence::_tkz_abi_needed(), 'at least the version it was built to call');
is(Time::Keeper::Recurrence::_tkz_abi_version(), $v[1], 'the same table on the next call');

diag("Testing Time::Keeper::Recurrence $Time::Keeper::Recurrence::VERSION, Time::Keeper $Time::Keeper::VERSION, Time::Keeper::Zone $Time::Keeper::Zone::VERSION, Perl $], $^X");

done_testing;
