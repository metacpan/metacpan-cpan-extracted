package Weather::YR::Model;
use Moose;
use namespace::autoclean;

=head1 NAME

Weather::YR::Model - Base class for model classes.

=head1 DESCRIPTION

Don't use this class directly. It's used as a "helper class" for other
classes.

=head1 METHODS

=head2 from

Returns this model's "from" date as a DateTime object.

=cut

has 'from' => (
    isa      => 'DateTime',
    is       => 'ro',
    required => 1,
);

=head2 to

Returns this model's "to" date as a DateTime object.

=cut

has 'to' => (
    isa      => 'DateTime',
    is       => 'ro',
    required => 1,
);

=head2 lang

Returns this model's language setting.

=cut

has 'lang' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
