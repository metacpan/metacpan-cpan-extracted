#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

use lib grep { -d } qw(./lib ../lib);
use Test::Easy;

sub pretty_epoch {
  my $epoch = shift;
  return "$epoch (i.e. " . (scalar localtime $epoch). ")";
}

# Answer the basic question of, 'Is this time within X seconds of this date?'
{
  my $some_epoch = int rand(time);
  my $some_localtime = localtime($some_epoch);
  my $expected_epoch = $some_epoch - 2;
  my $tolerance_seconds = 5;
  ok(
    time_nearly($some_localtime, $expected_epoch, $tolerance_seconds),
    "${\pretty_epoch $some_epoch} is     within   $tolerance_seconds seconds of $some_localtime"
  );

  my $other_epoch = ($some_epoch - 100);
  my $other_localtime = localtime($other_epoch);
  ok( ! time_nearly($some_localtime, $other_epoch, 99), "${\pretty_epoch $other_epoch} is not within  99 seconds of $some_localtime" );
  ok( time_nearly($some_localtime, $other_epoch, 100),  "${\pretty_epoch $other_epoch} is     within 100 seconds of $some_localtime" );
}

# Illustrate how to plug in support for other time formats
{
  # In practice this would happen inside your own test library wrapper: if you're doing this
  # in a lot of test files, you're missing a refactoring opportunity :-)
  Test::Easy::Time->add_format(
    _description => 'CCYY-MM-DD-hh-mm-ss',
    format_epoch_seconds => sub {
      my ($sec, $min, $hour, $mday, $month, $year) = localtime($_);
      $month += 1;
      $year += 1900;
      return join '-',
        map { length($_) == 1 ? sprintf '%02d', $_ : $_ }
        $year, $month, $mday, $hour, $min, $sec;
    },
  );

  local $ENV{TZ} = 'America/Los_Angeles';
  my $random_midnight = 895729680;        # Wed May 20 22:48:00 1998 - it's a keyrattle date
  my $weird_date = '1998-05-20-22-48-03'; # Wed May 20 22:48:03 1998 - deliberately within 5s of above
  ok( time_nearly($weird_date, $random_midnight, 5), "${\pretty_epoch $random_midnight} is within 5 seconds of $weird_date"  );
}

# Show how time_nearly() plays with deep_ok()
{
  my $some_epoch = int rand(time);
  my $some_date  = localtime $some_epoch;
  my $future_now = $some_epoch + 10;
  my $epsilon    = 15;

  my %got = (
    create_time => $some_date,
    name => 'maternal-Edam',
  );

  my %exp = (
    create_time => around_about($future_now, $epsilon),
    name => 'maternal-Edam',
  );

  isnt( $got{create_time}, $exp{create_time}, "$got{create_time} is not the same as ${\pretty_epoch $future_now}..." );
  deep_ok( \%got, \%exp, "...yet we can treat them as equivalent, and within $epsilon seconds of each other!" );

  my $now = localtime;
  my $time = time;
  deep_ok( [$now], [around_about($time, 0)], "$now is within 0 seconds of epoch time ${\pretty_epoch $time}" );
}
