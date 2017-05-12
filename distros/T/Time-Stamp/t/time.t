# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Time::Local () ; # core
use lib 't/lib';
use ControlTime;

# this script is just to ensure that some actual values can be tested
# without requiring time mocking mods to be installed

our $_timegm    = Time::Local::timegm(   5,10,18,16,2,111);
our $_timelocal = Time::Local::timelocal(5,10,18,16,2,111);
our $_time      = $_timegm;

BEGIN { ControlTime->mock_time_hires }

ControlTime->set($_time, 234567);

is(time(), $_time, 'global time() overridden');
is(join('.', Time::HiRes::gettimeofday()), "$_time.234567", 'hires time overridden');

BEGIN {
  require Time::Stamp;
  Time::Stamp->import(
    map {
      my $which = $_;
      "parse$which",
      "${which}stamp" => { -as => "${which}default" },
      "${which}stamp" => { -as => "${which}frac9", frac => 9 },
      "${which}stamp" => { -as => "${which}frac3", frac => 3 },
      map { ("${which}stamp" => { -as => "${which}$_", format => $_ }) } qw(easy numeric compact rfc3339)
    } qw( local gm )
  );
}

my $frac9 = '.234567000';
my $frac3 = '.235';

foreach my $test (
  [default => '2011-03-16T18:10:05Z'],
  [easy    => '2011-03-16 18:10:05 Z'],
  [numeric => '20110316181005'],
  [compact => '20110316_181005Z'],
  [rfc3339 => '2011-03-16T18:10:05Z'],
  [frac9   => "2011-03-16T18:10:05${frac9}Z", $frac9],
  [frac3   => "2011-03-16T18:10:05${frac3}Z", $frac3],
){
  my ($name, $stamp, $suffix) = (@$test, '');
  no strict 'refs';

  ControlTime->set($_timegm);
  is(&{"gm$name"}(),  $stamp, "gmstamp $name from time()");
  is(parsegm($stamp), $_timegm.$suffix, "parsegm reverts the stamp");

  $stamp =~ s/\D*Z$//;

  ControlTime->set($_timelocal);
  is &{"local$name"}(), $stamp, 'localstamp from time()';
  is parselocal($stamp), $_timelocal.$suffix, 'parselocal reverts stamp';
}

my $timegm    = Time::Local::timegm(   13, 18, 22, 8, 10, 93);
my $timelocal = Time::Local::timelocal(13, 18, 22, 8, 10, 93);

foreach my $test (
  [default => '1993-11-08T22:18:13Z'],
  [easy    => '1993-11-08 22:18:13 Z'],
  [numeric => '19931108221813'],
  [compact => '19931108_221813Z'],
  [rfc3339 => '1993-11-08T22:18:13Z'],
  [frac9   => "1993-11-08T22:18:13${frac9}Z", $frac9],
  [frac3   => "1993-11-08T22:18:13${frac3}Z", $frac3],
){
  my ($name, $stamp, $suffix) = (@$test, '');
  my $seconds;
  no strict 'refs';

  $seconds = $timegm . $suffix;
  is(&{"gm$name"}($seconds),  $stamp, "gmstamp $name from \$seconds");
  is(parsegm($stamp),       $seconds, "parsegm reverts the stamp");

  $stamp =~ s/\D*Z$//;
  $seconds = $timelocal . $suffix;
  is(&{"local$name"}($seconds),  $stamp, "localstamp $name from \$seconds");
  is(parselocal($stamp),       $seconds, "parselocal reverts the stamp");
}

my @gmtime    = (1, 2, 3, 4, 5, 67);
my @localtime = (1, 2, 3, 4, 5, 67);

foreach my $test (
  [default => '1967-06-04T03:02:01Z'],
  [easy    => '1967-06-04 03:02:01 Z'],
  [numeric => '19670604030201'],
  [compact => '19670604_030201Z'],
  [rfc3339 => '1967-06-04T03:02:01Z'],
  [frac9   => "1967-06-04T03:02:01${frac9}Z", $frac9],
  [frac3   => "1967-06-04T03:02:01${frac3}Z", $frac3],
){
  my ($name, $stamp, $suffix) = (@$test, '');
  my $timea;
  no strict 'refs';

  $timea = [@gmtime]; $timea->[0] .= $suffix;
  is(&{"gm$name"}(@$timea),      $stamp, "gmstamp $name from \@gmtime");
  is_deeply([parsegm($stamp)],   $timea, "parsegm reverts the stamp");

  $stamp =~ s/\D*Z$//;
  $timea = [@localtime]; $timea->[0] .= $suffix;
  is(&{"local$name"}(@$timea),      $stamp, "localstamp $name from \@localtime");
  is_deeply([parselocal($stamp)],   $timea, "parselocal reverts the stamp");
}

done_testing;
