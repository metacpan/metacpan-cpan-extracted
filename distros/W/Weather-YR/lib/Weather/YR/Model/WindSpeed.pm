package Weather::YR::Model::WindSpeed;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model';

=encoding utf-8

=head1 NAME

Weather::YR::Model::WindSpeed

=head1 DESCRIPTION

This class represents a data point's wind speed.

=head1 METHODS

This class inherits all the methods from L<Weather::YR::Model> and provides the
following new methods:

=head2 mps

Returns the current data point's wind speed in meters pr. second.

=cut

has 'mps' => (
    isa      => 'Num',
    is       => 'ro',
    required => 1,
);

=head2 fps

Returns the current data point's wind speed in feet pr. second.

=cut

has 'fps' => (
    isa        => 'Num',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_fps {
    my $self = shift;

    return sprintf( '%.1f', $self->mps * 3.28083989501312 );
}

=head2 beaufort

Returns the current data point's wind speed on the beaufort scale.

=cut

has 'beaufort' => (
    isa      => 'Num',
    is       => 'ro',
    required => 1,
);

=head2 name

Returns the current data point's wind speed described with a string.

Only Norwegian (bokmål) is supported at the moment.

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
