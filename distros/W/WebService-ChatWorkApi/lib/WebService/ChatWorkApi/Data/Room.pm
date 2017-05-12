use strict;
use warnings;
package WebService::ChatWorkApi::Data::Room;
use parent "WebService::ChatWorkApi::Data";
use Smart::Args;
use Mouse;

has room_id             => ( is => "ro", isa => "Int" );

has description         => ( is => "ro", isa => "Str"  );
has file_num            => ( is => "ro", isa => "Int"  );
has icon_path           => ( is => "ro", isa => "Str"  );
has last_update_time    => ( is => "ro", isa => "Int"  );
has mention_num         => ( is => "ro", isa => "Int"  );
has message_num         => ( is => "ro", isa => "Int"  );
has mytask_num          => ( is => "ro", isa => "Int"  );
has name                => ( is => "ro", isa => "Str"  );
has role                => ( is => "ro", isa => "Str"  );
has sticky              => ( is => "ro", isa => "Bool" );
has task_num            => ( is => "ro", isa => "Int"  );
has type                => ( is => "ro", isa => "Str"  );
has unread_num          => ( is => "ro", isa => "Int"  );

sub recent_messages {
    my $self      = shift;
    my %condition = @_;
    my $ds = $self->ds->relationship( "message" );
    my @messages = $ds->recent_messages( $self );
    my $messages_ref = $ds->grep( \%condition, \@messages );
    return @{ $messages_ref };
}

sub new_messages {
    my $self      = shift;
    my %condition = @_;
    my $ds = $self->ds->relationship( "message" );
    my @messages = $ds->new_messages( $self );
    my $messages_ref = $ds->grep( \%condition, \@messages );
    return @{ $messages_ref };
}

sub post_message {
    args_pos my $self,
             my $body;
    my $ds = $self->ds->relationship( "message" );
    my $message = $ds->post(
        room => $self,
        body => $body,
    );
    return $message;
}

1;
