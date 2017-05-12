package Weather::YR::Model::Precipitation;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model';

=head1 NAME

Weather::YR::Model::Precipitation

=head1 DESCRIPTION

This class represents one of a data point's many "precipitation" data points.

=head1 METHODS

This class inherits all the methods from L<Weather::YR::Model> and provides the
following new methods:

=head2 value

Returns the current data point's precipitation value.

=cut

has 'value' => (
    isa      => 'Num',
    is       => 'ro',
    required => 1,
);

=head2 min

Returns the current data point's minimum precipitation value.

=cut

has 'min' => (
    isa      => 'Maybe[Num]',
    is       => 'ro',
    required => 0,
    default  => 0,
);

=head2 max

Returns the current data point's maximum precipitation value.

=cut

has 'max' => (
    isa      => 'Maybe[Num]',
    is       => 'ro',
    required => 0,
    default  => 0,
);

=head2 symbol

Returns the current data point's symbol data, represented by a
L<Weather::YR::Model::Precipitation::Symbol> object.

=cut

has 'symbol' => (
    isa      => 'Weather::YR::Model::Precipitation::Symbol',
    is       => 'ro',
    required => 1,
);

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
