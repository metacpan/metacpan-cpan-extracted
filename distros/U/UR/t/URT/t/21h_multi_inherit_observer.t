use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 8;

my $parent1_fired;
setup_parent('Parent1', \$parent1_fired);

my $parent2_fired;
setup_parent('Parent2', \$parent2_fired);

UR::Object::Type->define(
    class_name => 'Child',
    is => ['Parent1', 'Parent2'],
);

for my $self ('Child', Child->create()) {
    ($parent1_fired, $parent2_fired) = (0, 0);
    is($parent1_fired, 0, 'Parent1 has not fired');
    $self->__signal_observers__('Parent1');
    is($parent1_fired, 1, 'Parent1 has fired');

    is($parent2_fired, 0, 'Parent2 has not fired');
    $self->__signal_observers__('Parent2');
    is($parent2_fired, 1, 'Parent2 has fired');
}

sub setup_parent {
    my $class_name = shift;
    my $fired_ref = shift;

    my $class = UR::Object::Type->define(
        class_name => $class_name,
        valid_signals => [$class_name],
    );

    $class_name->add_observer(
        aspect => $class_name,
        callback => sub { $$fired_ref++ },
    );
}
