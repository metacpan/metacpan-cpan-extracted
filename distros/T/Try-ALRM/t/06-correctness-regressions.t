use strict;
use warnings;

use Test::More;
use Try::ALRM;

sub dies (&);

subtest 'timeout aborts the current attempt and retries' => sub {
    my @events;

    retry {
        my ($attempt) = @_;
        push @events, "try-$attempt-before";
        sleep 2;
        push @events, "try-$attempt-after";    # must not happen
    }
    ALRM {
        my ($attempt) = @_;
        push @events, "alarm-$attempt";
    }
    finally {
        my ( $attempts, $success ) = @_;
        push @events, "finally-$attempts-$success";
    }
    timeout => 1,
    tries   => 2;

    is_deeply(
        \@events,
        [
            'try-1-before',
            'alarm-1',
            'try-2-before',
            'alarm-2',
            'finally-2-0',
        ],
        'timeout aborts attempt immediately and retries until exhausted'
    );
};

subtest 'successful attempt stops retry loop' => sub {
    my @events;

    retry {
        my ($attempt) = @_;
        push @events, "try-$attempt";

        sleep 2 if $attempt == 1;
        push @events, "success-$attempt" if $attempt == 2;
    }
    ALRM {
        my ($attempt) = @_;
        push @events, "alarm-$attempt";
    }
    finally {
        my ( $attempts, $success ) = @_;
        push @events, "finally-$attempts-$success";
    }
    timeout => 1,
    tries   => 3;

    is_deeply(
        \@events,
        [
            'try-1',
            'alarm-1',
            'try-2',
            'success-2',
            'finally-2-1',
        ],
        'retry stops after first successful attempt'
    );
};

subtest 'try_once only attempts once' => sub {
    my @events;

    try_once {
        my ($attempt) = @_;
        push @events, "try-$attempt";
        sleep 2;
        push @events, 'after-timeout';
    }
    ALRM {
        my ($attempt) = @_;
        push @events, "alarm-$attempt";
    }
    finally {
        my ( $attempts, $success ) = @_;
        push @events, "finally-$attempts-$success";
    }
    timeout => 1;

    is_deeply(
        \@events,
        [
            'try-1',
            'alarm-1',
            'finally-1-0',
        ],
        'try_once runs exactly one timed attempt'
    );
};

subtest 'finally runs before non-timeout exception is rethrown' => sub {
    my @events;

    my $error = eval {
        retry {
            push @events, 'try';
            die "boom\n";
        }
        finally {
            my ( $attempts, $success ) = @_;
            push @events, "finally-$attempts-$success";
        }
        timeout => 5,
        tries   => 3;

        1;
    };

    my $exception = $@;

    ok( !$error, 'retry died' );
    like( $exception, qr/\Aboom/, 'original exception was rethrown' );

    is_deeply(
        \@events,
        [
            'try',
            'finally-1-0',
        ],
        'finally ran before exception escaped'
    );
};

subtest 'main exception wins over finally exception' => sub {
    my @events;

    eval {
        retry {
            push @events, 'try';
            die "main failure\n";
        }
        finally {
            push @events, 'finally';
            die "finally failure\n";
        }
        timeout => 5,
        tries   => 2;
    };

    like( $@, qr/\Amain failure/, 'main exception is preserved' );

    is_deeply(
        \@events,
        [ 'try', 'finally' ],
        'finally still ran'
    );
};

subtest 'finally exception is thrown when main block succeeds' => sub {
    eval {
        retry {
            return;
        }
        finally {
            die "finally only failure\n";
        }
        timeout => 5,
        tries   => 1;
    };

    like( $@, qr/\Afinally only failure/, 'finally exception is thrown' );
};

subtest 'localized timeout and tries are visible inside blocks' => sub {
    my @seen;

    retry {
        push @seen, 'try-timeout=' . timeout;
        push @seen, 'try-tries=' . tries;
    }
    finally {
        push @seen, 'finally-timeout=' . timeout;
        push @seen, 'finally-tries=' . tries;
    }
    timeout => 7,
    tries   => 9;

    is_deeply(
        \@seen,
        [
            'try-timeout=7',
            'try-tries=9',
            'finally-timeout=7',
            'finally-tries=9',
        ],
        'localized timeout and tries are visible through accessors'
    );
};

subtest 'argument validation rejects bad trailing modifiers' => sub {
    like(
        dies {
            retry { } bogus => 1;
        },
        qr/Unknown retry argument 'bogus'/,
        'unknown trailing modifier rejected'
    );

    like(
        dies {
            retry { } timeout => 1, timeout => 2;
        },
        qr/Duplicate retry argument 'timeout'/,
        'duplicate trailing modifier rejected'
    );

    like(
        dies {
            retry { } timeout => 0;
        },
        qr/timeout must be an integer >= 1!/,
        'invalid timeout rejected'
    );

    like(
        dies {
            retry { } tries => 0;
        },
        qr/tries must be an integer >= 1!/,
        'invalid tries rejected'
    );

    like(
        dies {
            retry { } timeout => '1.5';
        },
        qr/timeout must be an integer >= 1!/,
        'fractional timeout rejected'
    );

    like(
        dies {
            retry { } tries => 'abc';
        },
        qr/tries must be an integer >= 1!/,
        'non-numeric tries rejected'
    );
};

done_testing();

sub dies (&) {
    my ($code) = @_;
    eval { $code->(); 1 };
    return $@;
}
