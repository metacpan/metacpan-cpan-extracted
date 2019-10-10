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
  call tm_sec   => $local_list[0];
  call tm_min   => $local_list[1];
  call tm_hour  => $local_list[2];
  call tm_mday  => $local_list[3];
  call tm_mon   => $local_list[4];
  call tm_year  => $local_list[5];
  call tm_wday  => $local_list[6];
  call tm_yday  => $local_list[7];
  call tm_isdst => $local_list[8];
}, 'local tm fields correct';

my $utc_tm = gmtime $time;
isa_ok $utc_tm, 'Time::FFI::tm';
is $utc_tm, object {
  call tm_sec   => $utc_list[0];
  call tm_min   => $utc_list[1];
  call tm_hour  => $utc_list[2];
  call tm_mday  => $utc_list[3];
  call tm_mon   => $utc_list[4];
  call tm_year  => $utc_list[5];
  call tm_wday  => $utc_list[6];
  call tm_yday  => $utc_list[7];
  call tm_isdst => $utc_list[8];
}, 'UTC tm fields correct';

my $str = ctime $time;
ok length($str), 'ctime returns string';
is asctime($local_tm), $str, 'local asctime matches ctime';
ok length(asctime($utc_tm)), 'utc asctime returns string';

is mktime($local_tm), $time, 'mktime returns original epoch';

my $dst_tm = Time::FFI::tm->new(
  tm_year  => 119,
  tm_mon   => 5,
  tm_mday  => 20,
  tm_hour  => 5,
  tm_min   => -5,
  tm_sec   => 0,
  tm_wday  => -1,
  tm_yday  => -1,
  tm_isdst => -1,
);
my $dst_epoch = Time::Local::timelocal(0, 55, 4, 20, 5, 2019);
is mktime($dst_tm), $dst_epoch, 'mktime returns (possibly) DST epoch';
is $dst_tm->tm_hour, 4, 'hour normalized';
is $dst_tm->tm_min, 55, 'minute normalized';
cmp_ok $dst_tm->tm_isdst, '>=', 0, 'isdst set';
cmp_ok $dst_tm->tm_wday,  '>=', 0, 'wday set';
cmp_ok $dst_tm->tm_yday,  '>=', 0, 'yday set';

is strftime('%Y', $utc_tm), $utc_list[5] + 1900, 'strftime return year';
is strftime('%H:%M:%S', $local_tm), sprintf('%02d:%02d:%02d', @local_list[2,1,0]), 'strftime returns right time';

SKIP: { skip "strptime not available" unless defined &strptime;
  my $tm = strptime('2300', '%Y');
  is $tm->tm_year, 400, 'strptime extract year';
  is $tm->tm_mon, 0, 'strptime default month';
  is $tm->tm_mday, 1, 'strptime default day of month';
  is $tm->tm_hour, 0, 'strptime default hour';
  is $tm->tm_min, 0, 'strptime default minute';
  is $tm->tm_sec, 0, 'strptime default second';
  is $tm->tm_isdst, -1, 'strptime DST undetermined';
  strptime('10-01', '%m-%d', $tm);
  is $tm->tm_mon, 9, 'strptime extract month';
  is $tm->tm_mday, 1, 'strptime extract day of month';
  strptime('5abc', '%H', $tm, \my $remaining);
  is $tm->tm_hour, 5, 'strptime extract hour';
  is $remaining, 'abc', 'unparsed input string';
}

SKIP: { skip "timelocal and timegm not available" unless defined &timelocal and defined &timegm;
  my $epoch = timelocal $local_tm;
  is $epoch, $time, 'timelocal returns original epoch';

  $epoch = timegm $utc_tm;
  is $epoch, $time, 'timegm returns original epoch';
}

done_testing;
