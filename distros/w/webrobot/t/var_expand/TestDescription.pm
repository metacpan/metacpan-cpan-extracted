package TestDescription;
use strict;
use warnings;

use Test::More;


my @result = (
    ['some text', 'Simple text'],
    ['Flintstone and Rubble', 'Expand config constants'],
    ['${fred} and ${barney}', 'Be case sensitive in config constants'],
    ['Barney first name is Barney', 'Include: Expand string (1)'],
    ['Barney second name is Rubble', 'Include: Expand string that is itself a constant (2)'],
    ['${barneys_firstname} and ${barneys_surname} must not be expanded', 'Check whether parameters to include are really local'],
    ['Barney first name is little-Barney', 'Include with a new set of parameters (1)'],
    ['Barney second name is little-Rubble', 'Include with a new set of parameters (2)'],
    ['Fred is little-Fred is little-Flintstone', 'Cascaded include: first include'],
    ['Now doubled: Fred is double-little-Fred is double-little-Flintstone', 'Cascaded include: second include'],
);

plan tests => scalar @result;

sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    $self->{i} = 0;
    return $self;
}

sub global_start {}
sub item_pre {}
sub global_end {}

sub item_post {
    my ($self, $r, $arg) = @_;
    my $desc = $arg->{description};
    my ($result_entry, $test_name) = @{$result[$self->{i}++]};
    is($desc, $result_entry, $test_name);
}

1;
