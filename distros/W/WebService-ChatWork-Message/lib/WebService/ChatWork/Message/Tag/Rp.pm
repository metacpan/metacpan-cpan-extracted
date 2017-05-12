use strict;
use warnings;
package WebService::ChatWork::Message::Tag::Rp;
use overload q{""} => \&as_string;
use Mouse;

extends "WebService::ChatWork::Message::Tag";

has account_id => ( is => "ro", isa => "Int" );
has room_id    => ( is => "ro", isa => "Int" );
has message_id => ( is => "ro", isa => "Int" );

sub as_string {
    my $self = shift;
    sprintf "[rp aid=%d to %d--%d]", $self->account_id, $self->room_id, $self->message_id;
}

1;
