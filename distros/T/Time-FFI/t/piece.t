use strict;
use warnings;
use Test2::V0;
use Test::Needs 'Time::Piece';
use Time::FFI::tm;

my $time = time;
my @localtime = CORE::localtime $time;
my @gmtime = CORE::gmtime $time;

my $local_tm = Time::FFI::tm->from_list(@localtime);
my $local_tp = $local_tm->to_object('Time::Piece', 1);
isa_ok $local_tp, 'Time::Piece';
is $local_tp, object {
  call sec   => $local_tm->tm_sec;
  call min   => $local_tm->tm_min;
  call hour  => $local_tm->tm_hour;
  call mday  => $local_tm->tm_mday;
  call mon   => $local_tm->tm_mon + 1;
  call year  => $local_tm->tm_year + 1900;
  call wday  => $local_tm->tm_wday + 1;
  call yday  => $local_tm->tm_yday;
  call epoch => $time;
}, 'local Time::Piece object';
my $local_from = Time::FFI::tm->from_object($local_tp, 1);
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
}, 'local tm structure from Time::Piece object';
is $local_from->epoch(1), $time, 'right epoch timestamp from local time';

my $utc_tm = Time::FFI::tm->from_list(@gmtime);
my $utc_tp = $utc_tm->to_object('Time::Piece', 0);
isa_ok $utc_tp, 'Time::Piece';
is $utc_tp, object {
  call sec   => $utc_tm->tm_sec;
  call min   => $utc_tm->tm_min;
  call hour  => $utc_tm->tm_hour;
  call mday  => $utc_tm->tm_mday;
  call mon   => $utc_tm->tm_mon + 1;
  call year  => $utc_tm->tm_year + 1900;
  call wday  => $utc_tm->tm_wday + 1;
  call yday  => $utc_tm->tm_yday;
  call epoch => $time;
}, 'UTC Time::Piece object';
my $utc_from = Time::FFI::tm->from_object($utc_tp, 0);
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
}, 'UTC tm structure from Time::Piece object';
is $utc_from->epoch(0), $time, 'right epoch timestamp from UTC time';

my $dst_tm = Time::FFI::tm->new(
  tm_year => 119,
  tm_mon  => 5,
  tm_mday => 20,
  tm_hour => 5,
  tm_min  => 0,
  tm_sec  => 0,
);
my $dst_tp = $dst_tm->to_object('Time::Piece', 1);
my $real_tp = Time::Piece::localtime->strptime('2019-06-20 05:00:00', '%Y-%m-%d %H:%M:%S');
is $dst_tp->epoch, $real_tp->epoch, '(possible) DST interpreted correctly';

done_testing;
