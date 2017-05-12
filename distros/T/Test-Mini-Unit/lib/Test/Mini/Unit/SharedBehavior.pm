# Base class for packages declared by the 'shared' keyword.
# @api private
package Test::Mini::Unit::SharedBehavior;

use Sub::Name;

sub import {
    my ($class) = @_;
    my $caller  = caller;

    for my $test (grep /^test./, keys %{"$class\::"}) {
        *{"$caller\::$test"} = subname $test => sub {
            eval {
                $class->can('setup')->(@_);
                $class->can($test)->(@_);
            };
            my $error = $@;
            eval { $class->can('teardown')->(@_); };
            die $error if $error;
        };
    }
}

sub setup    { }
sub teardown { }

1;
