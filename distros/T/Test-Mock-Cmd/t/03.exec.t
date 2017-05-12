use Test::More tests => 12;
use Test::Mock::Cmd::TestUtils;

# use Test::Output; # See rt 72976
BEGIN {
    *stdout_like = \&Test::Mock::Cmd::TestUtils::tmp_stdout_like_rt_72976;
}

use Test::Mock::Cmd::TestUtils::X;

BEGIN {
  SKIP: {
        skip '/bin/echo is required for these tests.', 4 if !-x '/bin/echo';

        stdout_like(
            sub {
                Test::Mock::Cmd::TestUtils::do_in_fork(
                    sub {
                        Test::Mock::Cmd::TestUtils::X::i_call_exec( "/bin/echo", "unmocked exec in other package defined before mock exec list" );
                        ok( 0, 'unmocked class exec() list did not exit' );
                    }
                );
            },
            qr/unmocked exec in other package defined before mock exec list/,
            'unmocked exec() in other package defined before mock, list'
        );

        stdout_like(
            sub {
                Test::Mock::Cmd::TestUtils::do_in_fork(
                    sub {
                        Test::Mock::Cmd::TestUtils::X::i_call_exec("/bin/echo unmocked exec in other package defined before mock exec string");
                        ok( 0, 'unmocked class exec() string did not exit' );
                    }
                );
            },
            qr/unmocked exec in other package defined before mock exec string/,
            'unmocked exec() in other package defined before mock, string'
        );

        stdout_like(
            sub {
                Test::Mock::Cmd::TestUtils::do_in_fork(
                    sub {

                        # Statement unlikely to be reached ... no warnings 'exec'; doesn't  help so we combine into one statement
                        exec( "/bin/echo", "unmocked exec defined before mock exec list" ) || ok( 0, 'unmocked exec() list did not exit' );
                    }
                );
            },
            qr/unmocked exec defined before mock exec list/,
            'unmocked exec() defined before mock, list'
        );

        stdout_like(
            sub {
                Test::Mock::Cmd::TestUtils::do_in_fork(
                    sub {

                        # Statement unlikely to be reached ... no warnings 'exec'; doesn't  help so we combine into one statement
                        exec("/bin/echo unmocked exec defined before mock exec string") || ok( 0, 'unmocked exec() string did not exit' );
                    }
                );
            },
            qr/unmocked exec defined before mock exec string/,
            'unmocked exec() defined before mock, string'
        );
    }
}

use Test::Mock::Cmd \&Test::Mock::Cmd::TestUtils::test_more_is_like_return_42;
use Test::Mock::Cmd::TestUtils::Y;

diag("Testing Test::Mock::Cmd $Test::Mock::Cmd::VERSION");

my $rc = exec( 'I am exec', 'I am exec', 'exec() mocked' );
is( $rc, 42, "exec() mocked RV" );

my $rca = Test::Mock::Cmd::TestUtils::Y::i_call_exec( 'I am exec in pkg', 'I am exec in pkg', 'exec() in pkg loaded after mocking is mocked' );
is( $rca, 42, "exec() in an other class (loaded after mocking) mocked RV list" );

SKIP: {
    skip '/bin/echo is required for these tests.', 4 if !-x '/bin/echo';

    stdout_like(
        sub {
            Test::Mock::Cmd::TestUtils::do_in_fork(
                sub {
                    Test::Mock::Cmd::TestUtils::X::i_call_exec( "/bin/echo", "exec call defined before mocking list not affected" );
                    ok( 0, 'unmocked class exec() list did not exit' );
                }
            );
        },
        qr/exec call defined before mocking list not affected/,
        'exec call defined before mocking list not affected'
    );

    stdout_like(
        sub {
            Test::Mock::Cmd::TestUtils::do_in_fork(
                sub {
                    Test::Mock::Cmd::TestUtils::X::i_call_exec("/bin/echo exec call defined before mocking string not affected");
                    ok( 0, 'unmocked class exec() string did not exit' );
                }
            );
        },
        qr/exec call defined before mocking string not affected/,
        'exec call defined before mocking string not affected'
    );

    stdout_like(
        sub {
            Test::Mock::Cmd::TestUtils::do_in_fork(
                sub {
                    Test::Mock::Cmd::orig_exec( "/bin/echo", "orig_exec list" );
                    ok( 0, 'unmocked exec() list did not exit' );
                }
            );
        },
        qr/orig_exec list/,
        'orig_exec list'
    );

    stdout_like(
        sub {
            Test::Mock::Cmd::TestUtils::do_in_fork(
                sub {
                    Test::Mock::Cmd::orig_exec("/bin/echo orig_exec string");
                    ok( 0, 'unmocked exec() string did not exit' );
                }
            );
        },
        qr/orig_exec string/,
        'orig_exec string'
    );
}
