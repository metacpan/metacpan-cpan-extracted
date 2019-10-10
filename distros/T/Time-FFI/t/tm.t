use strict;
use warnings;
use Test2::V0;
use Time::FFI::tm;

my @tm_members = qw(tm_sec tm_min tm_hour tm_mday tm_mon tm_year tm_wday tm_yday tm_isdst);

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

$tm = Time::FFI::tm->new(
  tm_year  => 119,
  tm_mon   => 5,
  tm_mday  => 20,
  tm_hour  => 5,
  tm_min   => 0,
  tm_sec   => 0,
  tm_wday  => -1,
  tm_yday  => -1,
  tm_isdst => -1,
);
my $local_tm = $tm->normalized(1);
is $tm->tm_wday,  -1, 'original tm wday unchanged';
is $tm->tm_yday,  -1, 'original tm yday unchanged';
is $tm->tm_isdst, -1, 'original tm isdst unchanged';
isnt $local_tm->tm_wday,  -1, 'new tm yday set';
isnt $local_tm->tm_yday,  -1, 'new tm wday set';
isnt $local_tm->tm_isdst, -1, 'new tm isdst set';
my $utc_tm = $tm->normalized(0);
is $tm->tm_wday,  -1, 'original tm wday unchanged';
is $tm->tm_yday,  -1, 'original tm yday unchanged';
is $tm->tm_isdst, -1, 'original tm isdst unchanged';
isnt $utc_tm->tm_wday, -1, 'new tm yday set';
isnt $utc_tm->tm_yday, -1, 'new tm wday set';
is $utc_tm->tm_isdst,   0, 'new tm isdst set';

done_testing;
