use strict;
use warnings;

use Test::More tests => 41;

use_ok 'Test::Parallel';

my @tests = (
    {},
    { max_process         => 1 },
    { max_process_per_cpu => 2 },
    { max_memory          => 128 },
);

foreach my $opts (@tests) {

    my $p = Test::Parallel->new(%$opts);
    isa_ok $p, 'Test::Parallel', "new with " . join( ' => ', %$opts );
    ok $p->add( sub { 1; } ),        "can add a scalar job";
    ok $p->add( sub { "string"; } ), "can add a string job";
    ok $p->add( sub { { hash => 42 }; } ), "can add a hash job";
    ok $p->add( sub { [ 1 .. 5 ]; } ), "can add an array job";
    ok $p->run(), "can run test in parallel";

    is_deeply $p->results(),
      [
        1, 'string',
        { 'hash' => 42 },
        [
            1,
            2,
            3,
            4,
            5
        ]
      ],
      "can get results from jobs";

    is_deeply $p->result(), $p->results(), "result is an alias on results";
}

# create a new object
my $p = Test::Parallel->new();

for my $job (qw/a list of jobs to run/) {
    ok $p->add( sub { compute_this_job($job); } ), "can add job $job";
}

ok $p->run(), "can run test in parallel";

is_deeply $p->results(),
  [
    {
        'time'                => 1,
        'job'                 => 'a',
        'your data key for a' => 1
    },
    {
        'time'                   => 1,
        'job'                    => 'list',
        'your data key for list' => 4
    },
    {
        'time'                 => 2,
        'your data key for of' => 2,
        'job'                  => 'of'
    },
    {
        'time'                   => 1,
        'your data key for jobs' => 4,
        'job'                    => 'jobs'
    },
    {
        'your data key for to' => 2,
        'time'                 => 2,
        'job'                  => 'to'
    },
    {
        'your data key for run' => 3,
        'time'                  => 0,
        'job'                   => 'run'
    }
  ],
  "can get results for all tests";

sub compute_this_job {
    my $job = shift || '';

    my $time = int( length($job) % 3 );

    # start some job
    sleep($time);
    print '- finish job ' . $job . "\n";

    # will never stop at the same time
    return {
        job    => $job, 'your data key for ' . $job => length($job),
        'time' => $time
    };
}

exit;

