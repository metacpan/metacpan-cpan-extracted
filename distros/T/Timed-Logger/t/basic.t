use strict;
use warnings;

use Test::More tests => 18;
use Test::Easy qw(deep_ok nearly_ok);

use_ok('Timed::Logger');
my $test_entry = new_ok('Timed::Logger::Entry', [bucket => 'test', started => '0']);
my $logger = new_ok('Timed::Logger');

deep_ok($logger->log, {}, 'got empty log by default');
is($logger->elapsed_total, 0, 'got 0 for empty logger total');
is($logger->elapsed_total('doesntexist'), 0, 'got 0 for empty logger total');

my $first_time = 0 + time();
{
  my $entry = $logger->start();
  $logger->finish($entry, { test => 'data 1' });
}

my $second_time = 0 + time();
{
  my $entry = $logger->start('test');
  sleep(3);
  $logger->finish($entry);
}

my $log = $logger->log;
is(0 + keys(%$log), 2, 'got two log buckets');

is(0 + @{$log->{default}}, 1, 'got expected number of entries');
nearly_ok($log->{default}->[0]->started, $first_time, 1, 'expected started time');
nearly_ok($log->{default}->[0]->elapsed, 0, 0.5, 'expected elapsed time');
deep_ok($log->{default}->[0]->data, { test => 'data 1' }, 'got expected log entries');

is(0 + @{$log->{test}}, 1, 'got expected number of entries');
nearly_ok($log->{test}->[0]->started, $second_time, 1, 'expected started time');
nearly_ok($log->{test}->[0]->elapsed, 3, 0.5, 'expected elapsed time');
is($log->{test}->[0]->data, undef, 'got expected log entries');

nearly_ok($logger->elapsed_total, 3, 0.5, 'expected total elapsed time');
nearly_ok($logger->elapsed_total('default'), 0, 0.5, 'expected total elapsed time');
nearly_ok($logger->elapsed_total('test'), 3, 0.5, 'expected total elapsed time');
