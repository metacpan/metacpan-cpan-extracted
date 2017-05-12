package Weather::YR::Model::Pressure;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model';

=head1 NAME

Weather::YR::Model::Pressure

=head1 DESCRIPTION

This class represents a data point's (air) "pressure".

=head1 METHODS

This class inherits all the methods from L<Weather::YR::Model> and provides the
following new methods:

=head2 hPa

Returns the current data point's (air) pressure in hPa (hectopascal).

=cut

has 'hPa' => (
    isa      => 'Num',
    is       => 'ro',
    required => 1,
);

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
