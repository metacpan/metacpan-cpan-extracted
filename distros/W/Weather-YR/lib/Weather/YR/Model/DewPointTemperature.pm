package Weather::YR::Model::DewPointTemperature;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model::Temperature';

=head1 NAME

Weather::YR::Model::DewPointTemperature

=head1 DESCRIPTION

This class represents a data point's "dew point temperature".

=head1 METHODS

This class inherits all the methods from L<Weather::YR::Model::Temperature>.

=cut

has '+celsius' => (
    isa      => 'Maybe[Num]',
    is       => 'ro',
    required => 1,
);

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
