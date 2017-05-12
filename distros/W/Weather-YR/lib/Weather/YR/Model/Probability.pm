package Weather::YR::Model::Probability;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model';

has 'value' => ( isa => 'Maybe[Num]', is => 'ro', required => 0, default => 0 );

__PACKAGE__->meta->make_immutable;

1;
