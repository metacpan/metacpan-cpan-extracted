use strict; use warnings;

use Test::Tester;

use Test::More;
use Test::Fatal;
use Test::Deep;

use Test::Shadow;

{
    package Foo;
    sub bar { 'bar' }
}

subtest 'arg checking' => sub {
    my ($premature, $result) = run_tests( sub {
        with_shadow Foo => bar => { in => { baz => 1 } },
        sub {
            Foo->bar(baz => 2);
        };
    });
    is $result->{ok}, 0, 'Failed test';
    is $result->{name}, 'Foo->bar unexpected parameters on call no. 1', 'Name ok';
    like $result->{diag}, qr/got : '2'/;
    like $result->{diag}, qr/expect : '1'/;
    like $result->{diag}, qr/\(Disabling wrapper\)/;
};

subtest 'arg checking with Test::Deep' => sub {
    my ($premature, $result) = run_tests( sub {
        with_shadow Foo => bar => { in => { baz => any(1,2) } },
        sub {
            Foo->bar(baz => 3);
        };
    });
    is $result->{ok}, 0, 'Failed test';
    is $result->{name}, 'Foo->bar unexpected parameters on call no. 1', 'Name ok';
    like $result->{diag}, qr/got +: '3'/;
    like $result->{diag}, qr/expected : Any of \( '1', '2' \)/;
    like $result->{diag}, qr/\(Disabling wrapper\)/;
};

subtest 'nonexistent method' => sub {
    like(
        exception { with_shadow Foo => baz => { }, sub { }; },
        qr/Foo has no such method baz/,
        'Foo has no such method baz'
    );
};

subtest 'output ref' => sub {
    like(
        exception { with_shadow Foo => bar => { out => [] }, sub { }; },
        qr/out is not a code ref!/,
        'out is not a code ref!'
    );
};

done_testing;
