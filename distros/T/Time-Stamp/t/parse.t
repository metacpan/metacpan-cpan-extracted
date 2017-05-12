# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Time::Local () ; # core

use Time::Stamp -parsers;

my $seconds = Time::Local::timegm(33, 22, 11, 17,  5, 93);

foreach my $test (
  [default => '1993-06-17T11:22:33Z'],
  [easy    => '1993-06-17 11:22:33 Z'],
  [numeric => '19930617112233'],
  [compact => '19930617_112233Z'],
){
  my ($name, $stamp) = @$test;
  $name = "gmtime $name";
  is(parsegm($stamp), $seconds, "parsed $name format");
  (my $fracstamp = $stamp) =~ s/(\d)(\D?Z?)$/$1.3456789$2/;
  is(parsegm($fracstamp), "$seconds.3456789", "parsed $name format with fraction");
  is(int(parsegm($fracstamp)), $seconds, "int $name format with fraction");
}

$seconds = Time::Local::timelocal(33, 22, 11, 17,  5, 93);

foreach my $test (
  [default => '1993-06-17T11:22:33'],
  [easy    => '1993-06-17 11:22:33'],
  [numeric => '19930617112233'],
  [compact => '19930617_112233'],
){
  my ($name, $stamp) = @$test;
  $name = "localtime $name";
  is(parselocal($stamp), $seconds, "parsed $name format");
  is(parselocal("$stamp.4560"), "$seconds.4560", "parsed $name format with fraction");
  is(int(parselocal("$stamp.4560")), $seconds, "int $name format with fraction");
}

is(scalar parsegm('oops'), undef, 'parsegm failed to parse');
is_deeply([parsegm('oops')], [],  'parsegm failed to parse');

done_testing;
