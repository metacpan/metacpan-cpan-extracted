package Weather::YR::Model::Precipitation::Symbol;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Model';

use Weather::YR::Lang::Symbol;

has 'id'     => ( isa => 'Str', is => 'rw', required => 1 );
has 'number' => ( isa => 'Int', is => 'rw', required => 1 );

has 'text'   => ( isa => 'Str', is => 'ro', lazy_build => 1 );

sub _build_text {
    my $self = shift;

    return Weather::YR::Lang::Symbol->new(
        number => $self->number,
        lang   => $self->lang,
    )->text;
}

__PACKAGE__->meta->make_immutable;

1;
