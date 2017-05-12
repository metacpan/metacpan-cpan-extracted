use Test::More;

use Test::Routini;

sub new {
    return bless({ test_attribute => "hello" }, shift);
}

Test::More::subtest("happy path", sub {
    $Test::Routini::test_cache = undef;
    is $Test::Routini::test_cache, undef;
    my $test_sub = sub { is shift->{'test_attribute'}, "hello"; };
    test "test0" => $test_sub;
    run_me;
} );

Test::More::subtest("Test registration", sub {
    $Test::Routini::test_cache = undef;
    is $Test::Routini::test_cache, undef;
    my $test_sub = sub { ok 1; };
    test "test1" => $test_sub;
    is $Test::Routini::test_cache->{"test1"}, $test_sub;
} );

Test::More::subtest("Run registered tests", sub {
    $Test::Routini::test_cache = undef;
    is $Test::Routini::test_cache, undef;
    my $test_run = 0;
    my $test_sub = sub { ok 1; $test_run++ };
    test "test2" => $test_sub;
    test "test3" => $test_sub;
    run_me();
    is $test_run, 2;
} );

Test::More::subtest("Run a test with run_test", sub {
    $Test::Routini::test_cache = undef;
    is $Test::Routini::test_cache, undef;
    my $test_sub = sub {
        my $self = shift;
        is $self, 'self';
    };
    run_test('self','test4', $test_sub);
} );

Test::More::subtest("run_test is called to execute each test", sub {
    $Test::Routini::test_cache = undef;
    is $Test::Routini::test_cache, undef;
    test 'test5' => sub {
        ok 0, 'failing test';
    };
    my $package = __PACKAGE__;
    no strict 'refs';
    my $orig = *{$package.'::run_test'}{CODE};
    eval "package $package; sub run_test { ok 1, 'run_test is called' }"; 
    run_me();
    *{$package.'::run_test'} = $orig;
} );

#Test::More::subtest("Fail if no tests run", sub {
#    $Test::Routini::test_cache = undef;
#    ok !eval {  run_me() };
##    is($@, "tests run\n");
#} );

done_testing;
1;
