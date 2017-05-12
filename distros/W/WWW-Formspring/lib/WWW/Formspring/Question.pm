package WWW::Formspring::Question;

use Moose;

use WWW::Formspring;

has 'id' => ( is => 'rw', isa => 'Int' );
has 'question' => ( is => 'rw', isa => 'Str' );
has 'time' => ( is => 'rw', isa => 'Str' );
has 'asked_by' => ( is => 'rw', isa => 'WWW::Formspring::User', predicate => 'has_asked_by' );
has 'asked_to' => ( is => 'rw', isa => 'WWW::Formspring::User', predicate => 'has_asked_to' );

sub ask {
    my ($self) = @_;

    WWW::Formspring->profile_ask($self);
}

__PACKAGE__->meta->make_immutable;

1
