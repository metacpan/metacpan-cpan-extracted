use strict;
use warnings;

use Test::More;
use Try::Tiny;
use Try::ALRM qw/tries timeout/;

subtest 'nested blocks restore tries and timeout' => sub {
    my @seen;

    Try::ALRM::retry {
        my ($outer_attempt) = @_;

        push @seen, [ 'outer start', tries, timeout ];

        Try::ALRM::retry {
            push @seen, [ 'inner retry', tries, timeout ];
        }
        Try::ALRM::finally {
            my ( $attempts, $success ) = @_;
            push @seen, [ 'inner finally', $attempts, $success ? 1 : 0 ];
        }
        timeout => 2,
        tries   => 1;

        push @seen, [ 'outer after inner', tries, timeout ];
    }
    Try::ALRM::finally {
        my ( $attempts, $success ) = @_;
        push @seen, [ 'outer finally', $attempts, $success ? 1 : 0 ];
    }
    timeout => 5,
    tries   => 1;

    is_deeply(
        \@seen,
        [
            [ 'outer start',       1, 5 ],
            [ 'inner retry',       1, 2 ],
            [ 'inner finally',     1, 1 ],
            [ 'outer after inner', 1, 5 ],
            [ 'outer finally',     1, 1 ],
        ],
        'inner block does not corrupt outer context'
    );
};

subtest 'inner timeout does not corrupt outer context' => sub {
    my @seen;

    Try::ALRM::retry {
        push @seen, [ 'outer start', tries, timeout ];

        Try::ALRM::retry {
            sleep 2;
        }
        Try::ALRM::ALRM {
            push @seen, [ 'inner alarm', tries, timeout ];
        }
        Try::ALRM::finally {
            my ( $attempts, $success ) = @_;
            push @seen, [ 'inner finally', $attempts, $success ? 1 : 0 ];
        }
        timeout => 1,
        tries   => 1;

        push @seen, [ 'outer after inner', tries, timeout ];
    }
    Try::ALRM::finally {
        my ( $attempts, $success ) = @_;
        push @seen, [ 'outer finally', $attempts, $success ? 1 : 0 ];
    }
    timeout => 5,
    tries   => 1;

    is_deeply(
        \@seen,
        [
            [ 'outer start',       1, 5 ],
            [ 'inner alarm',       1, 1 ],
            [ 'inner finally',     1, 0 ],
            [ 'outer after inner', 1, 5 ],
            [ 'outer finally',     1, 1 ],
        ],
        'inner timeout leaves outer tries/timeout intact'
    );
};

subtest 'Try::Tiny swallowed exception is treated as success' => sub {
    my $attempts = 0;
    my $caught   = 0;
    my $success;

    Try::ALRM::retry {
        $attempts++;

        try {
            die "boom\n";
        }
        catch {
            $caught++;
        };
    }
    Try::ALRM::finally {
        my ( undef, $s ) = @_;
        $success = $s;
    }
    timeout => 2,
    tries   => 3;

    is $attempts, 1, 'did not retry swallowed exception';
    is $caught,   1, 'exception was caught';
    ok $success,     'swallowed exception counts as success';
};

subtest 'Try::Tiny rethrown exception escapes' => sub {
    my $attempts = 0;

    my $ok = eval {
        Try::ALRM::retry {
            $attempts++;

            try {
                die "boom\n";
            }
            catch {
                die $_;
            };
        }
        timeout => 2,
        tries   => 3;

        1;
    };

    ok !$ok, 'rethrown exception escaped';
    like $@, qr/boom/, 'exception text preserved';
    is $attempts, 1, 'ordinary exception is not retried by Try::ALRM';
};

subtest 'Perl try works when supported' => sub {
    SKIP: {
        eval q{
            use feature 'try';
            no warnings 'experimental::try';
            1;
        } or skip "Perl try/catch not supported by this Perl: $@", 1;

        my $result = eval q{
            use feature 'try';
            no warnings 'experimental::try';

            my $attempts = 0;
            my $success;

            Try::ALRM::retry {
                $attempts++;

                try {
                    die "boom\n";
                }
                catch ($e) {
                    # Swallow exception; Try::ALRM should see success.
                }
            }
            Try::ALRM::finally {
                my (undef, $s) = @_;
                $success = $s;
            }
            timeout => 2,
            tries   => 3;

            [ $attempts, $success ? 1 : 0 ];
        };

        die $@ if $@;

        is_deeply(
            $result,
            [ 1, 1 ],
            'Perl try/catch composes when the exception is handled'
        );
    }
};

subtest 'eval interaction matches documented behavior' => sub {

    subtest 'eval swallows exception => treated as success (no retry)' => sub {
        my $attempts = 0;
        my $success;

        Try::ALRM::retry {
            $attempts++;

            eval {
                die "boom\n";
            };

            # swallow (do not rethrow)
        }
        Try::ALRM::finally {
            my ( undef, $s ) = @_;
            $success = $s;
        }
        timeout => 2,
        tries   => 3;

        is $attempts, 1, 'no retry when eval swallows exception';
        ok $success,     'swallowed exception counts as success';
    };

    subtest 'eval + rethrow => exception escapes (no retry)' => sub {
        my $attempts = 0;

        my $ok = eval {
            Try::ALRM::retry {
                $attempts++;

                eval {
                    die "boom\n";
                };

                die $@ if $@;   # rethrow
            }
            timeout => 2,
            tries   => 3;

            1;
        };

        ok !$ok, 'rethrown exception escaped retry block';
        like $@, qr/boom/, 'exception text preserved';
        is $attempts, 1, 'no retry on ordinary exception';
    };

    subtest 'eval without checking $@ => silent success' => sub {
        my $attempts = 0;
        my $success;

        Try::ALRM::retry {
            $attempts++;

            eval {
                die "boom\n";
            };

            # no $@ check at all
        }
        Try::ALRM::finally {
            my ( undef, $s ) = @_;
            $success = $s;
        }
        timeout => 2,
        tries   => 3;

        is $attempts, 1, 'no retry when $@ is ignored';
        ok $success,     'ignored exception treated as success';
    };

};

done_testing;
