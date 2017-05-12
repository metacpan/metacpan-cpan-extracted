use strict;
use warnings;
use utf8;
use Test::Tester;
use Test::More;

require Test::Power;

sub foo { 3 }

subtest 'ok' => sub {
    check_test(
        sub {
            Test::Power::expect(sub { foo() == 3 });
        },
        {
            ok => 1,
            name => "L14 : Test::Power::expect(sub { foo() == 3 });",
            diag => "",
        }
    );
};

subtest 'fail' => sub {
    check_test(
        sub {
            Test::Power::expect(sub { foo() == 2 });
        },
        {
            ok => 0,
            name => "L27 : Test::Power::expect(sub { foo() == 2 });",
            diag => "foo()\n   => 3",
        }
    );
};

done_testing;

