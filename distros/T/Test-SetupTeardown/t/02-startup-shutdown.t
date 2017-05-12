use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok 'Test::SetupTeardown';

{ # begin, no end

    my $begin_count = 0;
    my $environment = Test::SetupTeardown->new(begin => sub { $begin_count++ });
    my $did_i_run = 0;

    is($begin_count, 1,
       q{... and the begin closure has run});

    $environment->run_test('this is the description',
                           sub { $did_i_run = 1 });

    is($did_i_run, 1,
       q{... and an environment with begin runs the test fine});
}

my $end_count = 0;

{ # end, no begin

    my $environment = Test::SetupTeardown->new(end => sub { $end_count++ });
    my $did_i_run = 0;

    $environment->run_test('this is the description',
                           sub { $did_i_run = 1 });

    is($did_i_run, 1,
       q{... and an environment with begin runs the test fine});
}

is($end_count, 1,
   q{... and the end closure has run});

done_testing;
