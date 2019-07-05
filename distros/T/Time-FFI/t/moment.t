use strict;
use warnings;
use Test2::V0;
use Test::Needs 'Time::Moment';
use Time::FFI::tm;

my $time = time;
my @localtime = CORE::localtime $time;
my @gmtime = CORE::gmtime $time;

my $local_tm = Time::FFI::tm->from_list(@localtime);
my $local_mt = $local_tm->to_object('Time::Moment', 1);
isa_ok $local_mt, 'Time::Moment';
is $local_mt, object {
  call second => $local_tm->tm_sec;
  call minute => $local_tm->tm_min;
  call hour   => $local_tm->tm_hour;
  call day_of_month => $local_tm->tm_mday;
  call month  => $local_tm->tm_mon + 1;
  call year   => $local_tm->tm_year + 1900;
  call day_of_week  => $local_tm->tm_wday || 7; # Sunday == 7
  call day_of_year  => $local_tm->tm_yday + 1;
  call epoch  => $time;
}, 'local Time::Moment object';

my $utc_tm = Time::FFI::tm->from_list(@gmtime);
my $utc_mt = $utc_tm->to_object('Time::Moment', 0);
isa_ok $utc_mt, 'Time::Moment';
is $utc_mt, object {
  call second => $utc_tm->tm_sec;
  call minute => $utc_tm->tm_min;
  call hour   => $utc_tm->tm_hour;
  call day_of_month => $utc_tm->tm_mday;
  call month  => $utc_tm->tm_mon + 1;
  call year   => $utc_tm->tm_year + 1900;
  call day_of_week  => $utc_tm->tm_wday || 7; # Sunday == 7
  call day_of_year  => $utc_tm->tm_yday + 1;
  call epoch  => $time;
}, 'UTC Time::Moment object';

done_testing;
