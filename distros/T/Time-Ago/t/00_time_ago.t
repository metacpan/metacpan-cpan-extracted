#!/usr/bin/env perl

use strict;
use warnings;
use POSIX ':locale_h';
use Test::More;

my $CLASS = 'Time::Ago';

use_ok $CLASS;

isa_ok $CLASS->new, $CLASS, 'constructor';

setlocale(LC_ALL, '');
$ENV{LANGUAGE} = 'en';

#######################################################################

sub to_secs {
  my $secs = @_ ? shift() : 0;

  $secs += (shift() * 60)           if @_; # minutes
  $secs += (shift() * 60 * 60)      if @_; # hours
  $secs += (shift() * 60 * 60 * 24) if @_; # days

  return $secs;
}

my $round = sub { int($_[0] + 0.5) };

my $to_mins   = sub { $round->( $_[0] / 60 )              };
my $to_hours  = sub { $round->( $to_mins->($_) / 60 )     };
my $to_days   = sub { $round->( $to_mins->($_) / 1440 )   };
my $to_months = sub { $round->( $to_mins->($_) / 43200 )  };


my $method = 'in_words';
my $call = sub { $CLASS->$method(@_) };

# 0 <-> 29 secs => less than a minute
foreach (0..29) {
  is $call->($_), 'less than a minute', "$method, $_ seconds";
}

# 0 secs <-> 1 min, 29 secs => 1 minute
foreach (30..89) {
  is $call->($_), '1 minute', "$method, $_ seconds";
}

# 1 min, 30 secs <-> 44 mins, 29 secs => [2..44] minutes
foreach (90, 181, (44*60), (44*60+29)) {
  my $minutes = int(($_ / 60) + 0.5);
  is $call->($_), "$minutes minutes", "$method, $_ seconds";
}

# 44 mins, 30 secs <-> 89 mins, 29 secs => about 1 hour
foreach (to_secs(30, 44), to_secs(29, 89)) {
  is $call->($_), 'about 1 hour', "$method, $_ seconds";
}

# 89 mins, 30 secs <-> 23 hrs, 59 mins, 29 secs => about [2..24] hours
foreach (to_secs(30, 89), to_secs(29, 59, 23)) {
  my $hours = $to_hours->($_);
  is $call->($_), "about $hours hours", "$method, $_ seconds";
}

# 23 hrs, 59 mins, 30 secs <-> 41 hrs, 59 mins, 29 secs => 1 day
foreach (to_secs(30, 59, 23), to_secs(29, 59, 41)) {
  is $call->($_), '1 day', "$method, $_ seconds";
}

# 41 hrs, 59 mins, 30 secs <-> 29 days, 23 hrs, 59 mins, 29 secs
#   => [2..29] days
foreach (to_secs(30, 59, 41), to_secs(29,59,23,29)) {
  my $days = $to_days->($_);
  is $call->($_), "$days days", "$method, $_ seconds";
}

# 29 days, 23 hrs, 59 mins, 30 secs <-> 44 days, 23 hrs, 59 mins, 29 secs
#   => about 1 month
foreach (to_secs(30, 59, 23, 29), to_secs(29, 59, 23, 44)) {
  is $call->($_), 'about 1 month', "$method, $_ seconds";
}

# 44 days, 23 hrs, 59 mins, 30 secs <-> 59 days, 23 hrs, 59 mins, 29 secs
#   => about 2 months
foreach (to_secs(30, 59, 23, 44), to_secs(29, 59, 23, 59)) {
  is $call->($_), 'about 2 months', "$method, $_ seconds";
}

my $year = 365 * 60 * 60 * 24;
my $quarter = 131400 * 60; # minutes * secs

# 59 days, 23 hrs, 59 mins, 30 secs <-> 1 yr minus 1 sec => [2..12] months
foreach (to_secs(30, 59, 23, 59), $year - 1) {
  my $months = $to_months->($_);
  is $call->($_), "$months months", "$method, $_ seconds";
}

# 1 yr <-> 1 yr, 3 months => about 1 year
foreach ($year + 30, $year + $quarter - 60) {
  is $call->($_), 'about 1 year', "$method, $_ seconds";
}

# 1 yr, 3 months <-> 1 yr, 9 months => over 1 year
foreach ($year + $quarter, $year + ($quarter * 3) - 60) {
  is $call->($_), "over 1 year", "$method, $_ seconds";
}

my $two_years = $year * 2;

# 1 yr, 9 months <-> 2 yr minus 1 sec => almost 2 years
foreach ($year + ($quarter * 3), $two_years - 60) {
  is $call->($_), "almost 2 years", "$method, $_ seconds";
}

# 2 yrs <-> max time or date => (same rules as 1 yr)
foreach ($two_years, $two_years + $quarter - 60) {
  is $call->($_), "about 2 years", "$method, $_ seconds";
}

foreach ($two_years + $quarter, $two_years + ($quarter * 3) - 60) {
  is $call->($_), "over 2 years", "$method, $_ seconds";
}

foreach ($two_years + ($quarter * 3), 3 * $year - 60) {
  is $call->($_), "almost 3 years", "$method, $_ seconds";
}

#######################################################################

SKIP: {
  eval { require DateTime };
  skip 'DateTime not installed', 1 if $@;

  my $dt = DateTime->from_epoch(epoch => time);
  is $call->($dt), 'less than a minute',
    'DateTime object converted to epoch seconds';
}

#######################################################################

SKIP: {
  eval { require DateTime::Duration };
  skip 'DateTime::Duration not installed', 1 if $@;

  my $dur = DateTime::Duration->new(
    years  => 3,
    months => 10,
  );

  is $call->($dur), 'almost 4 years',
    'DateTime::Duration object converted to epoch seconds';
}

#######################################################################

# Tests for when include_seconds parameter is supplied

$call = sub { $CLASS->$method(@_, include_seconds => 1) };

foreach (0, 4) {
  is $call->($_), 'less than 5 seconds', "include_seconds, $_ seconds";
}

foreach (5, 9) {
  is $call->($_), 'less than 10 seconds', "include_seconds, $_ seconds";
}

foreach (10, 19) {
  is $call->($_), 'less than 20 seconds', "include_seconds, $_ seconds";
}

foreach (20, 39) {
  is $call->($_), 'half a minute', "include_seconds, $_ seconds";
}

foreach (49, 59) {
  is $call->($_), 'less than a minute', "include_seconds, $_ seconds";
}

foreach (60, 89) {
  is $call->($_), '1 minute', "include_seconds, $_ seconds";
}

#######################################################################

Test::More::done_testing();

1;
