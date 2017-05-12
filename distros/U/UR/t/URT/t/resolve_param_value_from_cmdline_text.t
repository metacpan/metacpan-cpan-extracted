use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use UR;

use Test::More tests => 3;

my $some_object_meta = UR::Object::Type->define(
    class_name => 'SomeObject',
    has => [
        name => {
            is => 'Text',
        },
    ],
);

my $some_command_meta = UR::Object::Type->define(
    class_name => 'SomeCommand',
    is => 'Command::V2',
    has => [
        some_objects => {
            is => 'SomeObject',
            is_many => 1,
            require_user_verify => 0,
        },
    ],
);

for my $name (qw(Alice Bob Eve)) {
    SomeObject->create(name => $name);
}

my $pmeta = $some_command_meta->properties(property_name => 'some_objects');
my %test_queries = (
    'list of names specified by "in clause"' => [ q(name in ['Alice'), q('Bob']) ],
    'list of names specified by colon' => [ q(name:Alice/Bob) ],
    'list of names'  => [ q(Alice), q(Bob) ],
);
for my $test (keys %test_queries) {
    my $value = $test_queries{$test};
    my @o = SomeCommand->resolve_param_value_from_cmdline_text({
        name => $pmeta->property_name,
        class => $pmeta->data_type,
        value => $value,
    });
    is(scalar(@o), 2, $test);
}
