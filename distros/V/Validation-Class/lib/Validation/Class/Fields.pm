# Container Class for Validation::Class::Field Objects

# Validation::Class::Fields is a container class for L<Validation::Class::Field>
# objects and is derived from the L<Validation::Class::Mapping> class.

package Validation::Class::Fields;

use strict;
use warnings;

use Validation::Class::Util '!has';
use Hash::Flatten ();
use Carp;

our $VERSION = '7.900057'; # VERSION

use base 'Validation::Class::Mapping';

use Validation::Class::Mapping;
use Validation::Class::Field;

sub add {

    my $self = shift;

    my $arguments = $self->build_args(@_);
    my @suspects  = sort keys %{$arguments};

    confess

        "Illegal field names detected, possible attempt to define validation " .
        "rules for a parameter containing an array of nested structures on " .
        "the following fields: " . join ", ", @suspects

        if grep /(:.*:|:\d+.)/, @suspects

    ;

    while (my ($key, $value) = each %{$arguments}) {

        # never overwrite
        unless (defined $self->{$key}) {
            if (isa_hashref($value)) {
                $value->{name} = $key;
            }
            $self->{$key} = $value; # accept an object as a value
            $self->{$key} = Validation::Class::Field->new($value) unless
                "Validation::Class::Field" eq ref $self->{$key}; # unless obj
        }

    }

    return $self;

}

sub AUTOLOAD {

    (my $routine = $Validation::Class::Fields::AUTOLOAD) =~ s/.*:://;

    my ($self) = @_;

    if ($routine) {

        if ($self->has($routine)) {
            return $self->get($routine);
        }

    }

    croak sprintf q(Can't locate object method "%s" via package "%s"),
        $routine, ((ref $_[0] || $_[0]) || 'main')
    ;

}

sub DESTROY {}

1;
