package Weather::YR::Model::Clouds;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model';

has 'cloudiness' => ( isa => 'Maybe[Num]', is => 'rw', required => 1 );
has 'low'        => ( isa => 'Maybe[Num]', is => 'rw', required => 1 );
has 'medium'     => ( isa => 'Maybe[Num]', is => 'rw', required => 1 );
has 'high'       => ( isa => 'Maybe[Num]', is => 'rw', required => 1 );

__PACKAGE__->meta->make_immutable;

1;
