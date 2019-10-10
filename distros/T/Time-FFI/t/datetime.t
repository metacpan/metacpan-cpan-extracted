use strict;
use warnings;
use Test2::V0;
use Test::Needs 'DateTime';
use Time::FFI::tm;

my $time = time;
my @localtime = CORE::localtime $time;
my @gmtime = CORE::gmtime $time;

my $local_tm = Time::FFI::tm->from_list(@localtime);
my $local_dt = $local_tm->to_object('DateTime', 1);
isa_ok $local_dt, 'DateTime';
is $local_dt, object {
  call second => $local_tm->tm_sec;
  call minute => $local_tm->tm_min;
  call hour   => $local_tm->tm_hour;
  call day    => $local_tm->tm_mday;
  call month  => $local_tm->tm_mon + 1;
  call year   => $local_tm->tm_year + 1900;
  call day_of_week => $local_tm->tm_wday || 7; # Sunday == 7
  call day_of_year => $local_tm->tm_yday + 1;
  call epoch  => $time;
}, 'local DateTime object';
my $local_from = Time::FFI::tm->from_object($local_dt, 1);
is $local_from, object {
  call tm_sec   => $local_tm->tm_sec;
  call tm_min   => $local_tm->tm_min;
  call tm_hour  => $local_tm->tm_hour;
  call tm_mday  => $local_tm->tm_mday;
  call tm_mon   => $local_tm->tm_mon;
  call tm_year  => $local_tm->tm_year;
  call tm_wday  => $local_tm->tm_wday;
  call tm_yday  => $local_tm->tm_yday;
  call tm_isdst => $local_tm->tm_isdst;
}, 'local tm structure from DateTime object';
is $local_from->epoch(1), $time, 'right epoch timestamp from local time';

my $utc_tm = Time::FFI::tm->from_list(@gmtime);
my $utc_dt = $utc_tm->to_object('DateTime', 0);
isa_ok $utc_dt, 'DateTime';
is $utc_dt, object {
  call second => $utc_tm->tm_sec;
  call minute => $utc_tm->tm_min;
  call hour   => $utc_tm->tm_hour;
  call day    => $utc_tm->tm_mday;
  call month  => $utc_tm->tm_mon + 1;
  call year   => $utc_tm->tm_year + 1900;
  call day_of_week => $utc_tm->tm_wday || 7; # Sunday == 7
  call day_of_year => $utc_tm->tm_yday + 1;
  call epoch  => $time;
}, 'UTC DateTime object';
my $utc_from = Time::FFI::tm->from_object($utc_dt, 0);
is $utc_from, object {
  call tm_sec   => $utc_tm->tm_sec;
  call tm_min   => $utc_tm->tm_min;
  call tm_hour  => $utc_tm->tm_hour;
  call tm_mday  => $utc_tm->tm_mday;
  call tm_mon   => $utc_tm->tm_mon;
  call tm_year  => $utc_tm->tm_year;
  call tm_wday  => $utc_tm->tm_wday;
  call tm_yday  => $utc_tm->tm_yday;
  call tm_isdst => $utc_tm->tm_isdst;
}, 'UTC tm structure from DateTime object';
is $utc_from->epoch(0), $time, 'right epoch timestamp from UTC time';

my $dst_tm = Time::FFI::tm->new(
  tm_year => 119,
  tm_mon  => 5,
  tm_mday => 20,
  tm_hour => 5,
  tm_min  => 0,
  tm_sec  => 0,
);
my $dst_dt = $dst_tm->to_object('DateTime', 1);
my $real_dt = DateTime->new(
  year   => 2019,
  month  => 6,
  day    => 20,
  hour   => 5,
  minute => 0,
  second => 0,
  time_zone => 'local',
);
is $dst_dt->epoch, $real_dt->epoch, '(possible) DST interpreted correctly';

done_testing;
