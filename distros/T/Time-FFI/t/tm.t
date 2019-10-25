use strict;
use warnings;
use Test2::V0;
use Time::FFI::tm;
use Time::localtime ();
use Time::gmtime ();

my @tm_members = qw(sec min hour mday mon year wday yday isdst);

my $tm = Time::FFI::tm->new;
is $tm, object { call $_ => 0 for @tm_members }, 'base tm struct';

my $time = time;

my @localtime = CORE::localtime $time;

$tm = Time::FFI::tm->new(map { ($tm_members[$_] => $localtime[$_]) } 0..$#tm_members);
is $tm, object { call $tm_members[$_] => $localtime[$_] for 0..$#tm_members }, 'populated tm struct';
is $tm->epoch(1), $time, 'epoch from tm struct';

$tm = Time::FFI::tm->from_list(@localtime);
is $tm, object { call $tm_members[$_] => $localtime[$_] for 0..$#tm_members }, 'populated tm struct from list';
is $tm->epoch(1), $time, 'epoch from tm struct';
is [$tm->to_list], \@localtime, 'tm struct to list';

my @gmtime = CORE::gmtime $time;

$tm = Time::FFI::tm->new(map { ($tm_members[$_] => $gmtime[$_]) } 0..$#tm_members);
is $tm, object { call $tm_members[$_] => $gmtime[$_] for 0..$#tm_members }, 'populated tm struct';
is $tm->epoch(0), $time, 'epoch from tm struct';

$tm = Time::FFI::tm->from_list(@gmtime);
is $tm, object { call $tm_members[$_] => $gmtime[$_] for 0..$#tm_members }, 'populated tm struct from list';
is $tm->epoch(0), $time, 'epoch from tm struct';
is [$tm->to_list], \@gmtime, 'tm struct to list';

my $localtime_tm = Time::localtime::localtime $time;

$tm = Time::FFI::tm->from_object($localtime_tm);
is $tm, object { call $_ => $localtime_tm->$_ for qw(sec min hour mday mon year) }, 'populated tm struct from Time::localtime';
is $tm->epoch(1), $time, 'epoch from tm struct';
is $tm->to_object('Time::tm'), object { call $_ => $tm->$_ for @tm_members }, 'Time::tm struct';

my $gmtime_tm = Time::gmtime::gmtime $time;

$tm = Time::FFI::tm->from_object($gmtime_tm);
is $tm, object { call $_ => $gmtime_tm->$_ for qw(sec min hour mday mon year) }, 'populated tm struct from Time::gmtime';
is $tm->epoch(0), $time, 'epoch from tm struct';
is $tm->to_object('Time::tm'), object { call $_ => $tm->$_ for @tm_members }, 'Time::tm struct';

$tm = Time::FFI::tm->new(
  year  => 119,
  mon   => 5,
  mday  => 20,
  hour  => 5,
  min   => 0,
  sec   => 0,
  wday  => -1,
  yday  => -1,
  isdst => -1,
);
my $local_tm = $tm->normalized(1);
is $tm->wday,  -1, 'original tm wday unchanged';
is $tm->yday,  -1, 'original tm yday unchanged';
is $tm->isdst, -1, 'original tm isdst unchanged';
isnt $local_tm->wday,  -1, 'new tm yday set';
isnt $local_tm->yday,  -1, 'new tm wday set';
isnt $local_tm->isdst, -1, 'new tm isdst set';
my $utc_tm = $tm->normalized(0);
is $tm->wday,  -1, 'original tm wday unchanged';
is $tm->yday,  -1, 'original tm yday unchanged';
is $tm->isdst, -1, 'original tm isdst unchanged';
isnt $utc_tm->wday, -1, 'new tm yday set';
isnt $utc_tm->yday, -1, 'new tm wday set';
is $utc_tm->isdst,   0, 'new tm isdst set';

done_testing;
