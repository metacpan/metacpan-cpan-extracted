package Weather::YR::Model::Temperature;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model';

=head1 NAME

Weather::YR::Model::Temperature

=head1 DESCRIPTION

This class represents a data point's "temperature".

=head1 METHODS

This class inherits all the methods from L<Weather::YR::Model> and provides the
following new methods:

=head2 celsius

Returns the current data point's temperature in celsius.

=cut

has 'celsius' => (
    isa      => 'Num',
    is       => 'ro',
    required => 1,
);

=head2 fahrenheit

Returns the current data point's temperature in fahrenheit.

=cut

sub fahrenheit {
    my $self = shift;

    my $fahrenheit = ( ($self->celsius * 9) / 5 ) + 32;

    return sprintf( '%.2f', $fahrenheit );
}

=head2 kelvin

Returns the current data point's temperature in kelvin.

=cut

sub kelvin {
    my $self = shift;

    return sprintf( '%.2f', $self->celsius + 273.15 );
}

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
