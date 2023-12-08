#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

use Data::Dumper;
use Scalar::Util 'refaddr';

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use TheSchwartz::JobScheduler::Job;

subtest 'Confirm default values' => sub {
    my $job = TheSchwartz::JobScheduler::Job->new();
    is( $job->grabbed_until, 0, 'Correct default value for grabbed_until' );
    ok( $job->run_after >= time, 'Correct default value for run_after' );
    done_testing;
};

subtest 'Create with new_from_array()' => sub {
    my $job = TheSchwartz::JobScheduler::Job->new(
        funcname => 'MyFunc',
        arg      => {
            arg1 => 'some value',
            arg2 => 'other value',
        },
        uniqkey => 555_444_333,
    );

    is( $job->funcname, 'MyFunc',                                        'Correct value' );
    is( $job->arg,      { arg1 => 'some value', arg2 => 'other value' }, 'Correct value' );
    is( $job->uniqkey,  555_444_333,                                     'Correct value' );
    done_testing;
};

done_testing;
