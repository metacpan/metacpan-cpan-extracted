# Container Class for Validation::Class::Mixin Objects

# Validation::Class::Mixins is a container class for L<Validation::Class::Mixin>
# objects and is derived from the L<Validation::Class::Mapping> class.

package Validation::Class::Mixins;

use strict;
use warnings;

use Validation::Class::Util '!has';

our $VERSION = '7.900057'; # VERSION

use base 'Validation::Class::Mapping';

use Validation::Class::Mixin;

sub add {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    while (my ($key, $value) = each %{$arguments}) {

        # do not overwrite
        unless (defined $self->{$key}) {
            $self->{$key} = $value; # accept an object as a value
            $self->{$key} = Validation::Class::Mixin->new($value)
                unless "Validation::Class::Mixin" eq ref $self->{$key}
            ;
        }

    }

    return $self;

}

1;
