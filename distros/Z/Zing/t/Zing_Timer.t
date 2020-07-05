use 5.014;

use strict;
use warnings;
use routines;

use lib 't/app';
use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Timer

=cut

=tagline

Timer Process

=cut

=abstract

Timer Process

=cut

=synopsis

  package MyApp;

  use parent 'Zing::Timer';

  sub schedules {
    [
      # every ten minutes
      ['*/10 * * * *', ['tasks'], { do => 1 }],
    ]
  }

  package main;

  my $myapp = MyApp->new;

  # $myapp->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Process

=cut

=description

This package provides a L<Zing::Process> which places pre-defined messages into
message queues based on time-based scehdules. It supports minute-level
resolution and functions similarly to a crontab (cron table).

=cut

=scenario schedules

The schedules method is meant to be implemented by a subclass and is
automatically invoked when the process is executed, it should return a list of
schedules. A single schedule takes the form of C<[$interval, $queues,
$message]> where C<$interval> is represented as a cron-expression or using one
of the predefined interval name, e.g. C<@yearly>, C<@annually>, C<@monthly>,
C<@weekly>, C<@weekend>, C<@daily>, C<@hourly>, or C<@minute>.

=example schedules

  # given: synopsis

  $myapp->schedules;

  # schedule structure
  # [$interval, $queues, $message, $adjustment]

  # predefined schedules

  # @annually is at 00:00 on day-of-month 1 in january
  # @daily is at 00:00 every day
  # @hourly is at minute 0 every hour
  # @minute is at every minute
  # @monthly is at 00:00 on day-of-month 1
  # @weekend is at 00:00 on saturday
  # @weekly is at 00:00 on monday
  # @yearly is at 00:00 on day-of-month 1 in january

  # other schedule examples

  # every minute
  # ['* * * * *', ['tasks'], { do => 1 }]

  # every hour (on the half hour)
  # ['30 * * * *', ['tasks'], { do => 1 }]

  # every 15th minute
  # ['*/15 * * * *', ['tasks'], { do => 1 }]

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('schedules', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
