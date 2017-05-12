#!perl

## Mock localtime()
BEGIN {
  my $my_time;

  *CORE::GLOBAL::localtime = \&localtime;

  sub localtime (;$) {
    return @$my_time if $my_time;
    return CORE::localtime($_[0]) if @_;
    return CORE::localtime();
  }
  sub set_localtime { $my_time = @_ ? [@_] : undef }
}


use strict;
use warnings;
use Test::More;
use Time::Duration::Parse::More;

sub ok_duration {
  my ($spec, $seconds, $msg) = @_;
  $msg = $spec unless $msg;
  my $got = eval { parse_duration($spec) };
  if   ($@) { fail("With '$msg' died with '$@'") }
  else      { is($got, $seconds, "$msg = $seconds (got $got)") }
}

sub fail_duration {
  my $spec = shift;
  eval { parse_duration($spec) };
  if (my $e = $@) {
    chomp($e);
    pass($e);
  }
  else {
    fail("Expression '$spec' was parsed without errors - not cool");
  }
}

sub ok_midnight {
  my ($localtime, $value) = @_;
  set_localtime(reverse(split(/:/, $localtime)));
  ok_duration('midnight', $value, "$localtime to midnight");
}


subtest 'extended expressions' => sub {
  ok_duration '1 minute, 30 seconds',      90;
  ok_duration '1 minute plus 15 seconds',  75;
  ok_duration '1 minute minus 15 seconds', 45;

  ok_duration '1,3 m', 78;
  ok_duration ',3 m',  18;
  ok_duration '.3 m',  18;
  ok_duration '0.3 m', 18;

  ok_duration '  4,3 ', 4;
  ok_duration ' ,3',    0;
  ok_duration ' .3 ',   0;
  ok_duration '0.7 ',   1;

  ok_duration 'minus 15 seconds',                 -15;
  ok_duration 'minus 15 seconds plus minus plus', -15;

  ok_duration '1 day minus 2.5 hours and 10 minutes plus 15,6 seconds', 76816;

  ok_duration '3 h minus 2:30', 1800;
  ok_duration '1:1:1',          3661;
  ok_duration '100:200:300',    372300;

  ok_duration '3h',                        3 * 3600;
  ok_duration '2m',                        2 * 60;
  ok_duration '1s',                        1;
  ok_duration '21s3m',                     3 * 60 + 21;
  ok_duration '3h2m1s',                    3 * 3600 + 2 * 60 + 1;
  ok_duration '1s3m2h',                    2 * 3600 + 3 * 60 + 1;
  ok_duration '1 hour 3h-2m1s 40 seconds', 4 * 3600 - 2 * 60 + 1 + 40;

  fail_duration '1 hour1s3m2h';
  fail_duration 'mi nus';
  fail_duration 'minus 15 seconds plu s plus';
  fail_duration '1M aaand minus 15 secs';
};


subtest 'Time::Duration::Parse tests' => sub {
  ok_duration '3',                       3;
  ok_duration '3 seconds',               3;
  ok_duration '3 Seconds',               3;
  ok_duration '3 s',                     3;
  ok_duration '6 minutes',               360;
  ok_duration '6 minutes and 3 seconds', 363;
  ok_duration '6 Minutes and 3 seconds', 363;
  ok_duration '1 day',                   86400;
  ok_duration '1 day, and 3 seconds',    86403;
  ok_duration '-1 seconds',              -1;
  ok_duration '-6 minutes',              -360;

  ok_duration '1 hr', 3600;
  ok_duration '3s',   3;
  ok_duration '1hr',  3600;

  ok_duration '1d 2:03',    93780;
  ok_duration '1d 2:03:01', 93781;
  ok_duration '1d -24:00',  0;
  ok_duration '2:03',       7380;

  ok_duration ' 1s   ', 1;
  ok_duration '   1  ', 1;
  ok_duration '  1.3 ', 1;

  ok_duration '1.5h',     5400;
  ok_duration '1,5h',     5400;
  ok_duration '1.5h 30m', 7200;
  ok_duration '1.9s',     2;      # Check rounding
  ok_duration '1.3s',     1;
  ok_duration '1.3',      1;
  ok_duration '1.9',      2;

  ok_duration '1h,30m, 3s',    5403;
  ok_duration '1h and 30m,3s', 5403;
  ok_duration '1,5h, 3s',      5403;
  ok_duration '1,5h and 3s',   5403;
  ok_duration '1.5h, 3s',      5403;
  ok_duration '1.5h and 3s',   5403;

  fail_duration '3 sss';
  fail_duration '6 minutes and 3 sss';
  fail_duration '6 minutes, and 3 seconds a';
};


subtest 'midnight' => sub {
  ok_midnight('23:55:01', 59 + 4 * 60);
  ok_midnight('00:00:00', 24 * 60 * 60);
  ok_midnight('00:00:01', 24 * 60 * 60 - 1);

  set_localtime();
  my $midnight_before = parse_duration('midnight');
  sleep(2);
  my $midnight_after = parse_duration('midnight');
  ok((($midnight_before - $midnight_after) >= 1),
    "parse_duration('midnight') is not cached (before $midnight_before, after $midnight_after)");

  my $midnight_complex = parse_duration('midnight plus 6 hours');
  ok(($midnight_complex - $midnight_after - 6 * 60 * 60) < 2, 'complex expressions with midnight ok');
};

done_testing();
