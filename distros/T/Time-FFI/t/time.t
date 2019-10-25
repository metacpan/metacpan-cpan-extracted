use strict;
use warnings;
use Test2::V0;
use Time::FFI ':all';
use Time::Local ();

my $time = time;
my @local_list = CORE::localtime $time;
my @utc_list = CORE::gmtime $time;

my $local_tm = localtime $time;
isa_ok $local_tm, 'Time::FFI::tm';
is $local_tm, object {
  call sec   => $local_list[0];
  call min   => $local_list[1];
  call hour  => $local_list[2];
  call mday  => $local_list[3];
  call mon   => $local_list[4];
  call year  => $local_list[5];
  call wday  => $local_list[6];
  call yday  => $local_list[7];
  call isdst => $local_list[8];
}, 'local tm fields correct';

my $utc_tm = gmtime $time;
isa_ok $utc_tm, 'Time::FFI::tm';
is $utc_tm, object {
  call sec   => $utc_list[0];
  call min   => $utc_list[1];
  call hour  => $utc_list[2];
  call mday  => $utc_list[3];
  call mon   => $utc_list[4];
  call year  => $utc_list[5];
  call wday  => $utc_list[6];
  call yday  => $utc_list[7];
  call isdst => $utc_list[8];
}, 'UTC tm fields correct';

my $str = ctime $time;
ok length($str), 'ctime returns string';
is asctime($local_tm), $str, 'local asctime matches ctime';
ok length(asctime($utc_tm)), 'utc asctime returns string';

is mktime($local_tm), $time, 'mktime returns original epoch';

my $dst_tm = Time::FFI::tm->new(
  year  => 119,
  mon   => 5,
  mday  => 20,
  hour  => 5,
  min   => -5,
  sec   => 0,
  wday  => -1,
  yday  => -1,
  isdst => -1,
);
my $dst_epoch = Time::Local::timelocal(0, 55, 4, 20, 5, 2019);
is mktime($dst_tm), $dst_epoch, 'mktime returns (possibly) DST epoch';
is $dst_tm->hour, 4, 'hour normalized';
is $dst_tm->min, 55, 'minute normalized';
cmp_ok $dst_tm->isdst, '>=', 0, 'isdst set';
cmp_ok $dst_tm->wday,  '>=', 0, 'wday set';
cmp_ok $dst_tm->yday,  '>=', 0, 'yday set';

is strftime('%Y', $utc_tm), $utc_list[5] + 1900, 'strftime return year';
is strftime('%H:%M:%S', $local_tm), sprintf('%02d:%02d:%02d', @local_list[2,1,0]), 'strftime returns right time';

SKIP: { skip "strptime not available" unless defined &strptime;
  my $tm = strptime('2300', '%Y');
  is $tm->year, 400, 'strptime extract year';
  is $tm->mon, 0, 'strptime default month';
  is $tm->mday, 0, 'strptime default day of month';
  is $tm->hour, 0, 'strptime default hour';
  is $tm->min, 0, 'strptime default minute';
  is $tm->sec, 0, 'strptime default second';
  is $tm->isdst, -1, 'strptime DST undetermined';
  strptime('10-01', '%m-%d', $tm);
  is $tm->mon, 9, 'strptime extract month';
  is $tm->mday, 1, 'strptime extract day of month';
  strptime('5abc', '%H', $tm, \my $remaining);
  is $tm->hour, 5, 'strptime extract hour';
  is $remaining, 'abc', 'unparsed input string';
}

SKIP: { skip "timelocal and timegm not available" unless defined &timelocal and defined &timegm;
  my $epoch = timelocal $local_tm;
  is $epoch, $time, 'timelocal returns original epoch';

  $epoch = timegm $utc_tm;
  is $epoch, $time, 'timegm returns original epoch';
}

done_testing;
