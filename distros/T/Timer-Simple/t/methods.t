# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Timer::Simple';
eval "require $mod" or die $@;

# for non-hires clocks sleep for 2 to make sure we crossed at least 1 second
# but don't slow down the tests if hires is available
sub nap { select(undef, undef, undef, ($_[0]->{hires} ? 0.25 : 2)); }

# new
my $t = new_ok($mod);
ok(exists($t->{started}), 'auto start');
nap($t);
ok($t->elapsed > 0, 'timing')
  or diag explain $t;

# new, start
$t = new_ok($mod, [start => 0]);
ok(!exists($t->{started}), 'no auto start');
is(eval { $t->elapsed; 1 }, undef, 'died without start');
like($@, qr/Timer never started/, 'died without start');
$t->start;
is(eval { $t->elapsed; 1 }, 1, 'success after timer started');

SKIP: {
  eval 'require Time::HiRes'
    or skip 2, 'Time::HiRes required for testing hires option';

  $t = new_ok($mod);
  ok( $t->{hires}, 'loaded HiRes');

  # hms
  like(scalar $t->hms, qr/^\d+:\d+:\d+\.\d+$/, 'default format');
  # time
  is(ref($t->time), 'ARRAY', 'hires time value');
}

{
  $t = new_ok($mod, [hires => 0]);
  ok(!$t->{hires}, 'skipped HiRes');

  # hms
  like(scalar new_ok($mod, [hires => 0])->hms, qr/^\d+:\d+:\d+$/, 'default format');
  # time
  is(ref($t->time), '', 'integer time value');
}

# hms
$t = new_ok($mod);
my @hms = $t->hms;
is(scalar @hms, 3, 'got hours, minutes, and seconds in list context');

like(scalar $t->hms, qr/^\d{2}:\d{2}:\d{2}(\.\d+)?$/, 'default hms');
$t->{hms} = '%04d-%04d-%d';
like(scalar $t->hms, qr/^\d{4}-\d{4}-\d+?$/, 'hms w/ object format');
like(scalar $t->hms('%d_%d_%f'), qr/^\d+_\d+_\d+\.\d+$/, 'hms w/ passed format');
# format changed above
like($t->string('short'), qr/\d+(\.\d+)?s \(\d+-\d+-\d+(\.\d+)?\)/, 'string(short)');

$t = new_ok($mod); # back to defaults

# elapsed, stop
ok($t->elapsed <  eval { nap($t); $t->elapsed }, 'seconds increase');
$t->stop;
ok($t->elapsed == eval { nap($t); $t->elapsed }, 'seconds stopped');
is($t->stop, do { nap($t); $t->stop }, 'stop only once');

# string()
$t->{string} = 'hms';
is(' ' . $t->hms, " $t", 'stringification');
$t->{string} = 'elapsed';
is(' ' . $t->elapsed, " $t", 'stringification');
$t->{string} = 'short';
is(' ' . $t->string('short'), " $t", 'stringification');
$t->{string} = sub { ref($_[0]) };
is(" $mod", " $t", 'stringification');

# string(format)
foreach my $test (
  [elapsed => qr/^\d+(\.\d+)?$/],
  [hms     => qr/^\d+:\d+:\d+(\.\d+)?$/],
  [short   => qr/^\d+(\.\d+)?s \(\d+:\d+:\d+(\.\d+)?\)$/],
  [human   => qr/^\d+ hours \d+ minutes \d+(\.\d+)? seconds$/],
  [full    => qr/^\d+(\.\d+)? seconds \(\d+ hours \d+ minutes \d+(\.\d+)? seconds\)$/],
  [rps     => qr/^\d+(\.\d+)?s \(\d+(\.\d+)?\/s\)$/],
){
  my ($format, $exp) = @$test;
  like($t->string($format), $exp, "string($format)");
}

subtest stop => sub {
  # test that stop() doesn't call elapsed in void context
  is($t->stop, $t->elapsed, 'stop returns elapsed');
  delete $t->{started};

  is(eval { $t->stop }, undef, 'stop calls elapsed');
  like($@, qr/Timer never started/, 'stop calls elapsed');

  is(eval { $t->stop; 1 }, 1, 'stop in void context does not call elapsed');
  is($@, '', 'stop in void context does not call elapsed');

  is(eval { $t->stop }, undef, 'stop calls elapsed');
  like($@, qr/Timer never started/, 'stop calls elapsed');
};

done_testing;
