package Weather::YR::Model::WindDirection;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model';

=head1 NAME

Weather::YR::Model::WindDirection

=head1 DESCRIPTION

This class represents a data point's wind direction.

=head1 METHODS

This class inherits all the methods from L<Weather::YR::Model> and provides the
following new methods:

=head2 degrees

Returns the current data point's wind direction in degrees.

=cut

has 'degrees' => (
    isa      => 'Num',
    is       => 'ro',
    required => 1,
);

=head2 name

Returns the current data point's wind direction as a name, ie. "N" for north,
"SW" for south-east etc.

=cut

has 'name' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
