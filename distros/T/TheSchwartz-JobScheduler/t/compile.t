#!perl
use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

subtest 'Code is syntactically correct' => sub {
    use TheSchwartz::JobScheduler;
    pass('Compile ok');
    done_testing;
};

done_testing;
