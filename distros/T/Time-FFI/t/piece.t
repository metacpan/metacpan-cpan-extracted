use strict;
use warnings;
use Test2::V0;
use Test::Needs {'Time::Piece' => '1.16'};
use Time::FFI::tm;

my $time = time;
my @localtime = CORE::localtime $time;
my @gmtime = CORE::gmtime $time;

my $local_tm = Time::FFI::tm->from_list(@localtime);
my $local_tp = $local_tm->to_object('Time::Piece', 1);
isa_ok $local_tp, 'Time::Piece';
is $local_tp, object {
  call sec   => $local_tm->sec;
  call min   => $local_tm->min;
  call hour  => $local_tm->hour;
  call mday  => $local_tm->mday;
  call mon   => $local_tm->mon + 1;
  call year  => $local_tm->year + 1900;
  call wday  => $local_tm->wday + 1;
  call yday  => $local_tm->yday;
  call epoch => $time;
}, 'local Time::Piece object';
my $local_from = Time::FFI::tm->from_object($local_tp);
is $local_from, object {
  call sec   => $local_tm->sec;
  call min   => $local_tm->min;
  call hour  => $local_tm->hour;
  call mday  => $local_tm->mday;
  call mon   => $local_tm->mon;
  call year  => $local_tm->year;
}, 'local tm structure from Time::Piece object';
is $local_from->epoch(1), $time, 'right epoch timestamp from local time';

my $utc_tm = Time::FFI::tm->from_list(@gmtime);
my $utc_tp = $utc_tm->to_object('Time::Piece', 0);
isa_ok $utc_tp, 'Time::Piece';
is $utc_tp, object {
  call sec   => $utc_tm->sec;
  call min   => $utc_tm->min;
  call hour  => $utc_tm->hour;
  call mday  => $utc_tm->mday;
  call mon   => $utc_tm->mon + 1;
  call year  => $utc_tm->year + 1900;
  call wday  => $utc_tm->wday + 1;
  call yday  => $utc_tm->yday;
  call epoch => $time;
}, 'UTC Time::Piece object';
my $utc_from = Time::FFI::tm->from_object($utc_tp);
is $utc_from, object {
  call sec   => $utc_tm->sec;
  call min   => $utc_tm->min;
  call hour  => $utc_tm->hour;
  call mday  => $utc_tm->mday;
  call mon   => $utc_tm->mon;
  call year  => $utc_tm->year;
}, 'UTC tm structure from Time::Piece object';
is $utc_from->epoch(0), $time, 'right epoch timestamp from UTC time';

my $dst_tm = Time::FFI::tm->new(
  year => 119,
  mon  => 5,
  mday => 20,
  hour => 5,
  min  => 0,
  sec  => 0,
);
my $dst_tp = $dst_tm->to_object('Time::Piece', 1);
my $real_tp = Time::Piece::localtime->strptime('2019-06-20 05:00:00', '%Y-%m-%d %H:%M:%S');
is $dst_tp->epoch, $real_tp->epoch, '(possible) DST interpreted correctly';

done_testing;
