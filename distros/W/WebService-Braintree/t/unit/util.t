# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree::Util qw(
    to_instance_array
    validate_id
);
use WebService::Braintree::TestHelper;

use Test::Deep;

# This is an internal method only. It is NOT exported.
subtest "Flatten Hashes" => sub {
    my $flatten = WebService::Braintree::Util->can('__flatten');

    is_deeply($flatten->({}), {}, "empty hash");
    is_deeply($flatten->({"a" => "1"}), {"a" => "1"}, "One element.");
    is_deeply($flatten->({"a" => {"b" => "1"}}), {"a[b]" => "1"}, "One namespace");
    is_deeply($flatten->({"a" => {"b" => "1"}, "a2" => {"q" => "r"}}), {"a[b]" => "1", "a2[q]" => "r"}, "Two horizontal namespace");
    is_deeply($flatten->({"a" => {"b" => {"c" => "1"}}}), {"a[b][c]" => "1"}, "Vertical merging");
};

# difference_arrays is now moved to AdvancedSearchNodes::MultipleValuesNode
#subtest "difference arrays" => sub {
#    cmp_deeply(difference_arrays(['a', 'b'], ['a', 'b']), []);
#    cmp_deeply(difference_arrays(['a', 'b'], ['a']), ['b']);
#    cmp_deeply(difference_arrays(['a', 'b'], ['b']), ['a']);
#    cmp_deeply(difference_arrays(['a'], ['a', 'b']), []);
#};

{
    package Testing::Object;

    sub new {
        my $class = shift;
        my ($param) = @_;

        my $self = {};
        $self->{param} = $param;
        return bless $self, $class;
    }
}

subtest to_instance_array => sub {
    subtest 'not arrayref of parameters' => sub {
        my $params = 'a';
        my $objs = to_instance_array($params, 'Testing::Object');
        is(scalar(@$objs), 1, 'one item in the array');
        is($objs->[0]{param}, $params, "... and the value was preserved");
    };

    subtest 'arrayref of parameters' => sub {
        my $params = [ 'a', 'b', 'c' ];
        my $objs = to_instance_array($params, 'Testing::Object');
        is(scalar(@$objs), scalar(@$params), 'right number of items');
        cmp_deeply([map { $_->{param} } @$objs], $params, "... and the values were preserved");
    };
};

subtest validate_id => sub {
    ok(!validate_id(), 'validate_id of nothing is false');
    ok(!validate_id(undef), 'validate_id of undefined is false');
    ok(!validate_id(""), 'validate_id of empty is false');
    ok(!validate_id(" "), 'validate_id of space is false');
    ok(validate_id("1"), 'validate_id of anything else is true');
};

done_testing();
