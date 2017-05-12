use strict;
use warnings;
package WebService::ChatWorkApi::DataSet::Message;
use parent "WebService::ChatWorkApi::DataSet";
use Readonly;
use Smart::Args;
use Mouse;
use WebService::ChatWorkApi::Data::Message;

Readonly my $FORCE_ON  => 1;
Readonly my $FORCE_OFF => 0;

has data  => ( is => "ro", isa => "Str",  default => sub { "WebService::ChatWorkApi::Data::Message" } );

sub recent_messages {
    args_pos my $self,
             my $room;
    return map { $self->bless( %{ $_ } ) } $self->dh->messages( $room->room_id, $FORCE_ON )->list;
}

sub new_messages {
    args_pos my $self,
             my $room;
    return map { $self->bless( %{ $_ } ) } $self->dh->messages( $room->room_id, $FORCE_OFF )->list;
}

sub post {
    args my $self,
         my $room,
         my $body;

    return $self->bless( $self->dh->post_message( $room->room_id, $body )->data );
}

1;
