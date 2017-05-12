use strict;
use warnings;

use t::Util qw(expect_fail);
use Test::More;
BEGIN {
    use_ok('Test::EasyMock',
           qw{
               create_mock
               expect
               replay
               verify
           });
}
use Test::Exception;

# ----
# Tests.
subtest 'expected but not invoke' => sub {
    my $mock = create_mock();
    expect($mock->foo);
    replay($mock);
    expect_fail { verify($mock) };
};

# ----
done_testing;
