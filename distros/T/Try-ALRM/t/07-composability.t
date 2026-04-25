use strict;
use warnings;

use Test::More;
use Try::ALRM;

subtest 'outer timeout survives inner try_once' => sub {
    my @events;

    retry {
        my ($attempt) = @_;

        push @events, "outer-start-$attempt";

        try_once {
            push @events, 'inner-start';
            sleep 0;
            push @events, 'inner-end';
        }
        timeout => 1;

        sleep 2;

        push @events, 'outer-after-sleep';
    }
    ALRM {
        my ($attempt) = @_;
        push @events, "outer-alarm-$attempt";
    }
    finally {
        my ( $attempts, $success ) = @_;
        push @events, "outer-finally-$attempts-$success";
    }
    timeout => 1,
    tries   => 1;

    is_deeply(
        \@events,
        [
            'outer-start-1',
            'inner-start',
            'inner-end',
            'outer-alarm-1',
            'outer-finally-1-0',
        ],
        'inner try_once does not cancel outer timeout'
    );
};

subtest 'inner timeout does not corrupt outer finally accounting' => sub {
    my @events;

    retry {
        my ($outer_attempt) = @_;
        push @events, "outer-start-$outer_attempt";

        try_once {
            push @events, 'inner-start';
            sleep 2;
            push @events, 'inner-after-sleep';
        }
        ALRM {
            my ($inner_attempt) = @_;
            push @events, "inner-alarm-$inner_attempt";
        }
        finally {
            my ( $inner_attempts, $inner_success ) = @_;
            push @events, "inner-finally-$inner_attempts-$inner_success";
        }
        timeout => 1;

        push @events, 'outer-after-inner';
    }
    ALRM {
        my ($outer_attempt) = @_;
        push @events, "outer-alarm-$outer_attempt";
    }
    finally {
        my ( $outer_attempts, $outer_success ) = @_;
        push @events, "outer-finally-$outer_attempts-$outer_success";
    }
    timeout => 5,
    tries   => 1;

    is_deeply(
        \@events,
        [
            'outer-start-1',
            'inner-start',
            'inner-alarm-1',
            'inner-finally-1-0',
            'outer-after-inner',
            'outer-finally-1-1',
        ],
        'inner timeout is contained and outer block can still succeed'
    );
};

subtest 'nested retry can timeout and retry independently' => sub {
    my @events;

    retry {
        my ($outer_attempt) = @_;
        push @events, "outer-start-$outer_attempt";

        retry {
            my ($inner_attempt) = @_;
            push @events, "inner-start-$inner_attempt";

            if ( $inner_attempt == 1 ) {
                sleep 2;
                push @events, 'inner-after-timeout';
            }

            push @events, "inner-success-$inner_attempt";
        }
        ALRM {
            my ($inner_attempt) = @_;
            push @events, "inner-alarm-$inner_attempt";
        }
        finally {
            my ( $inner_attempts, $inner_success ) = @_;
            push @events, "inner-finally-$inner_attempts-$inner_success";
        }
        timeout => 1,
        tries   => 2;

        push @events, 'outer-after-inner';
    }
    ALRM {
        my ($outer_attempt) = @_;
        push @events, "outer-alarm-$outer_attempt";
    }
    finally {
        my ( $outer_attempts, $outer_success ) = @_;
        push @events, "outer-finally-$outer_attempts-$outer_success";
    }
    timeout => 5,
    tries   => 1;

    is_deeply(
        \@events,
        [
            'outer-start-1',
            'inner-start-1',
            'inner-alarm-1',
            'inner-start-2',
            'inner-success-2',
            'inner-finally-2-1',
            'outer-after-inner',
            'outer-finally-1-1',
        ],
        'inner retry timeout/retry cycle does not corrupt outer retry'
    );
};

subtest 'outer timeout can expire while inner scope is active' => sub {
    my @events;

    retry {
        my ($outer_attempt) = @_;
        push @events, "outer-start-$outer_attempt";

        try_once {
            push @events, 'inner-start';
            sleep 3;
            push @events, 'inner-after-sleep';
        }
        ALRM {
            my ($inner_attempt) = @_;
            push @events, "inner-alarm-$inner_attempt";
        }
        finally {
            my ( $inner_attempts, $inner_success ) = @_;
            push @events, "inner-finally-$inner_attempts-$inner_success";
        }
        timeout => 5;

        push @events, 'outer-after-inner';
    }
    ALRM {
        my ($outer_attempt) = @_;
        push @events, "outer-alarm-$outer_attempt";
    }
    finally {
        my ( $outer_attempts, $outer_success ) = @_;
        push @events, "outer-finally-$outer_attempts-$outer_success";
    }
    timeout => 1,
    tries   => 1;

    is_deeply(
        \@events,
        [
            'outer-start-1',
            'inner-start',
            'outer-alarm-1',
            'inner-finally-1-0',
            'outer-finally-1-0',
        ],
        'outer timeout wins if it expires while inner scope is active'
    );
};

done_testing;
