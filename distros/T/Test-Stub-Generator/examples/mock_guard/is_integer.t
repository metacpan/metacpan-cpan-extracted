use strict;
use warnings;

use Test::More;
use Test::Deep::Matcher qw(is_integer is_string);
use Test::Mock::Guard;
use Test::Stub::Generator qw(make_repeat_method);

###
# sample package (for mocking test)
###
package Some::Class;

sub new { bless {}, shift }

# not implementation
sub has_permission {
    my ($self, $user_id) = @_;
    return 0;
}

# target method
sub get_authorized_user_id {
    my ($self, $user_ids) = @_;
    my $authorized_user_ids = [];
    for my $user_id (@$user_ids) {
        push @$authorized_user_ids, $user_id if($self->has_permission($user_id));
    }
    return $authorized_user_ids;
}

###
# testcode
###
package main;

my $obj = Some::Class->new;
my $guard = mock_guard(
    $obj => {
        'has_permission' => make_repeat_method(
            # checking arguments and control return_values
            { expects => [is_integer], return => 1 },
            { message => "has_permission's arguments is ok" },
        ),
    },
);

is_deeply(
    $obj->get_authorized_user_id([1,2]),
    [1,2],
    'get_authorized_user_id is ok'
);

done_testing;
