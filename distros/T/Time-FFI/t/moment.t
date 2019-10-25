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
  call second => $local_tm->sec;
  call minute => $local_tm->min;
  call hour   => $local_tm->hour;
  call day_of_month => $local_tm->mday;
  call month  => $local_tm->mon + 1;
  call year   => $local_tm->year + 1900;
  call day_of_week  => $local_tm->wday || 7; # Sunday == 7
  call day_of_year  => $local_tm->yday + 1;
  call epoch  => $time;
}, 'local Time::Moment object';
my $local_from = Time::FFI::tm->from_object($local_mt);
is $local_from, object {
  call sec   => $local_tm->sec;
  call min   => $local_tm->min;
  call hour  => $local_tm->hour;
  call mday  => $local_tm->mday;
  call mon   => $local_tm->mon;
  call year  => $local_tm->year;
}, 'local tm structure from Time::Moment object';
is $local_from->epoch(1), $time, 'right epoch timestamp from local time';

my $utc_tm = Time::FFI::tm->from_list(@gmtime);
my $utc_mt = $utc_tm->to_object('Time::Moment', 0);
isa_ok $utc_mt, 'Time::Moment';
is $utc_mt, object {
  call second => $utc_tm->sec;
  call minute => $utc_tm->min;
  call hour   => $utc_tm->hour;
  call day_of_month => $utc_tm->mday;
  call month  => $utc_tm->mon + 1;
  call year   => $utc_tm->year + 1900;
  call day_of_week  => $utc_tm->wday || 7; # Sunday == 7
  call day_of_year  => $utc_tm->yday + 1;
  call epoch  => $time;
}, 'UTC Time::Moment object';
my $utc_from = Time::FFI::tm->from_object($utc_mt);
is $utc_from, object {
  call sec   => $utc_tm->sec;
  call min   => $utc_tm->min;
  call hour  => $utc_tm->hour;
  call mday  => $utc_tm->mday;
  call mon   => $utc_tm->mon;
  call year  => $utc_tm->year;
}, 'UTC tm structure from Time::Moment object';
is $utc_from->epoch(0), $time, 'right epoch timestamp from UTC time';

subtest dst_check => sub {
  test_needs 'Role::Tiny', 'Time::Moment::Role::TimeZone';

  my $dst_tm = Time::FFI::tm->new(
    year => 119,
    mon  => 5,
    mday => 20,
    hour => 5,
    min  => 0,
    sec  => 0,
  );
  my $dst_mt = $dst_tm->to_object('Time::Moment', 1);
  my $real_mt = Role::Tiny->create_class_with_roles('Time::Moment', 'Time::Moment::Role::TimeZone')->new(
    year   => 2019,
    month  => 6,
    day    => 20,
    hour   => 5,
    minute => 0,
    second => 0,
  )->with_system_offset_same_local;
  is $dst_mt->epoch, $real_mt->epoch, '(possible) DST interpreted correctly';
};

done_testing;
