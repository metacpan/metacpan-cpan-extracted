package Weather::YR::Model::Fog;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model';

=head1 NAME

Weather::YR::Model::Fog

=head1 DESCRIPTION

This class represents a data point's "fog".

=head1 METHODS

This class inherits all the methods from L<Weather::YR::Model> and provides the
following new methods:

=head2 percent

Returns the current data point's fog percentage.

=cut

has 'percent' => (
    isa      => 'Maybe[Num]',
    is       => 'ro',
    required => 1,
);

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
