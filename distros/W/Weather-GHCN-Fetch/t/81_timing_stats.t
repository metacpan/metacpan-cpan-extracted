# Test suite for GHCN

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Weather::GHCN::TimingStats;

package Weather::GHCN::TimingStats;

use Test::More tests => 26;
use Test::Exception;

use Const::Fast;

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $EMPTY  => '';

use_ok 'Weather::GHCN::TimingStats';

my $tobj;
my @expected;
my @got;

$tobj = new_ok 'Weather::GHCN::TimingStats';

can_ok $tobj, 'start';
can_ok $tobj, 'stop';
can_ok $tobj, 'get_timers';
can_ok $tobj, 'get_duration';
can_ok $tobj, 'get_note';
can_ok $tobj, 'finish';


is $tobj->start('mytimer'),         undef, 'start timer';
is $tobj->stop('mytimer'),          undef, 'stop timer';
ok $tobj->get_duration('mytimer'), 'duration is non-zero';

is $tobj->start('timer_with_note'),         undef, 'start timer_with_note';
is $tobj->stop('timer_with_note', 'done'),  undef, 'timer_with_note "done"';
ok $tobj->get_duration('timer_with_note'),  'timer_with_note duration is non-zero';
is $tobj->get_note('timer_with_note'),      'done', 'timer_with_note note is "done"';

is $tobj->finish, 0, 'finish';

is $tobj->start('_Overall'),        undef, 'start special _Overall timer';

is $tobj->start('outer'),         undef, 'start outer timer';
sleep 0.1;
is $tobj->start('inner'),         undef, 'start outer timer';
sleep 0.2;
is $tobj->stop('inner'),          undef, 'stop outer timer';
sleep 0.3;
is $tobj->stop('outer'),          undef, 'stop outer timer';

is $tobj->start('no_stop'),       undef, 'start without stop';

# intentionally leaving out the stop for _Overall

my @warnings = $tobj->finish;
# uncoverable branch false
if (@warnings) {
    like $warnings[0], qr/forcing stop of timer/, 'finish returned with warnings';
} else {
    ok !@warnings, 'finish returned no warnings';
}

ok $tobj->get_duration('_Other'),  'finish inserts _Other';
ok $tobj->get_duration('_Overall'),  'finish inserts _Overall';

my @timers = $tobj->get_timers;
ok @timers, 'get_timers';