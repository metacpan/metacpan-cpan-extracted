package Weather::YR::DataPoint;
use Moose;
use namespace::autoclean;

=head1 NAME

Weather::YR::DataPoint - Base class for data points.

=head1 DESCRIPTION

Don't use this class directly. It is used as a "helper class" for other classes.

=head1 METHODS

=head2 from

Returns this data point's "from" date as a DateTime object.

=cut

has 'from' => (
    isa      => 'DateTime',
    is       => 'ro',
    required => 1,
);

=head2 to

Returns this data point's "to" date as a DateTime object.

=cut

has 'to' => (
    isa      => 'DateTime',
    is       => 'ro',
    required => 1,
);

=head2 type

Returns this data point's "type" value.

=cut

has 'type' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
