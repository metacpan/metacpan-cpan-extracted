use strict;
use warnings;
package WebService::ChatWorkApi::DataSet::Room;
use parent "WebService::ChatWorkApi::DataSet";
use Data::Dumper;
use Carp ( );
use Readonly;
use Smart::Args;
use Mouse;
use WebService::ChatWorkApi::Data::Room;

has data => ( is => "ro", isa => "Str", default => sub { "WebService::ChatWorkApi::Data::Room" } );

sub retrieve {
    args_pos my $self,
             my $room_id;
    my $res = $self->dh->room( $room_id );
    return $self->bless( $res->data );
}

sub retrieve_all {
    my $self = shift;
    my $res = $self->dh->rooms;
    return map { $self->bless( %{ $_ } ) } $res->list;
}

1;
