# Error Handling Object for Fields and Classes

# Validation::Class::Errors is responsible for error handling in
# Validation::Class derived classes on both the class and field levels
# respectively and is derived from the L<Validation::Class::Listing> class.

package Validation::Class::Errors;

use strict;
use warnings;

use Validation::Class::Util '!has', '!hold';

our $VERSION = '7.900057'; # VERSION

use base 'Validation::Class::Listing';

sub add {

    my $self = shift;

    my $arguments = isa_arrayref($_[0]) ? $_[0] : [@_];

    push @{$self}, @{$arguments};

    @{$self} = ($self->unique);

    return $self;

}

sub to_string {

    my ($self, $delimiter, $transformer) = @_;

    $delimiter = ', ' unless defined $delimiter; # default is a comma-space

    $self->each($transformer) if $transformer;

    return $self->join($delimiter);

}

1;
