
use Test2::V0;

use Test2::Plugin::TodoFailOnSuccess;  # report unexpected TODO success

use Test2::Tools::Basic;    # for "todo" sub
use Test2::Todo;            # for "todo" object

plan 5;

pass "passed";

my $value = my $expected_value = 'abc';

# Lexical scope TODO:
#
{
    my $todo = todo 'Not expected to pass';
    is 'abc', 'abc', "Got expected value";
}

# Coderef TODO:
#
todo 'Not expected to pass either' => sub {
    is $value, $expected_value, "Got expected value";
};

# Object-oriented TODO:
#
my $todo = Test2::Todo->new( reason => 'Still not expected to pass' );
is $value, $expected_value, "Got expected value";
$todo->end;

pass "also passed";

done_testing();

