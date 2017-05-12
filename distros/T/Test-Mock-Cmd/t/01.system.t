use Test::More tests => 20;
use Test::Mock::Cmd::TestUtils;

# use Test::Output; # See rt 72976
BEGIN {
    *stdout_like = \&Test::Mock::Cmd::TestUtils::tmp_stdout_like_rt_72976;
}

use Test::Mock::Cmd::TestUtils::X;

BEGIN {
  SKIP: {
        skip '/bin/echo is required for these tests.', 8 if !-x '/bin/echo';

        stdout_like(
            sub {
                my $rrc = Test::Mock::Cmd::TestUtils::X::i_call_system( "/bin/echo", "unmocked system in other package defined before mock system list" );
                is( $rrc, 0, "unmocked system() in other package defined before mock, RC true (list)" );
            },
            qr/unmocked system in other package defined before mock system list/,
            'unmocked system() in other package defined before mock, list'
        );

        stdout_like(
            sub {
                my $rrc = Test::Mock::Cmd::TestUtils::X::i_call_system("/bin/echo unmocked system in other package defined before mock system string");
                is( $rrc, 0, "unmocked system() in other package defined before mock, RC true (string)" );
            },
            qr/unmocked system in other package defined before mock system string/,
            'unmocked system() in other package defined before mock, string'
        );

        stdout_like(
            sub {
                my $rrc = system( "/bin/echo", "unmocked system list" );
                is( $rrc, 0, "unmocked system() RC true (list)" );
            },
            qr/unmocked system list/,
            'unmocked system() list'
        );

        stdout_like(
            sub {
                my $rrc = system("/bin/echo unmocked system string");
                is( $rrc, 0, "unmocked system() RC true (string)" );
            },
            qr/unmocked system string/,
            'unmocked system() string'
        );
    }
}

use Test::Mock::Cmd \&Test::Mock::Cmd::TestUtils::test_more_is_like_return_42;
use Test::Mock::Cmd::TestUtils::Y;

diag("Testing Test::Mock::Cmd $Test::Mock::Cmd::VERSION");

my $rc = system( 'I am system', 'I am system', 'system() mocked' );
is( $rc, 42, "system() mocked RV" );

my $rca = Test::Mock::Cmd::TestUtils::Y::i_call_system( 'I am system in pkg', 'I am system in pkg', 'system() in pkg loaded after mocking is mocked' );
is( $rca, 42, "system() in an other class (loaded after mocking) mocked RV list" );

SKIP: {
    skip '/bin/echo is required for these tests.', 8 if !-x '/bin/echo';

    stdout_like(
        sub {
            my $rrc = Test::Mock::Cmd::TestUtils::X::i_call_system( "/bin/echo", "system call defined before mocking list not affected" );
            is( $rrc, 0, "system call defined before mocking not affected RC correct (list)" );
        },
        qr/system call defined before mocking list/,
        'orig_system() list'
    );

    stdout_like(
        sub {
            my $rrc = Test::Mock::Cmd::TestUtils::X::i_call_system("/bin/echo system call defined before mocking string not affected");
            is( $rrc, 0, "system call defined before mocking not affected RC correct (string)" );
        },
        qr/system call defined before mocking string/,
        'orig_system() list'
    );

    stdout_like(
        sub {
            my $rrc = Test::Mock::Cmd::orig_system( "/bin/echo", "orig_system list" );
            is( $rrc, 0, "orig_system() RC correct (list)" );
        },
        qr/orig_system list/,
        'orig_system() list'
    );

    stdout_like(
        sub {
            my $rrc = Test::Mock::Cmd::orig_system("/bin/echo orig_system string");
            is( $rrc, 0, "orig_system() RC correct (string)" );
        },
        qr/orig_system string/,
        'orig_system() string'
    );
}
