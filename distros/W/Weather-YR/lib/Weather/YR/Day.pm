package Weather::YR::Day;
use Moose;
use namespace::autoclean;

=head1 NAME

Weather::YR::Day - Base class representing a day containing data points.

=head1 DESCRIPTION

Don't use this class directly. It is used as a "helper class" for other classes.

=head1 METHODS

=head2 date

Returns this day's date as a DateTime object.

=cut

has 'date' => (
    isa      => 'DateTime',
    is       => 'ro',
    required => 1,
);

=head2 datapoints

Returns an array reference of this day's data points, represented as
L<Weather::YR::DataPoint> objects.

=cut

has 'datapoints' => (
    isa      => 'ArrayRef[Weather::YR::DataPoint]',
    is       => 'ro',
    required => 1,
);

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
