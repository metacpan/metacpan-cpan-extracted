use strict;
use warnings;
package WebService::ChatWorkApi::Data::Me;
use parent "WebService::ChatWorkApi::Data";
use Mouse;

has account_id          => ( is => "ro", isa => "Int" );

has avatar_image_url    => ( is => "ro", isa => "Str" );
has chatwork_id         => ( is => "ro", isa => "Str" );
has department          => ( is => "ro", isa => "Str" );
has facebook            => ( is => "ro", isa => "Str" );
has introduction        => ( is => "ro", isa => "Str" );
has mail                => ( is => "ro", isa => "Str" );
has name                => ( is => "ro", isa => "Str" );
has organization_id     => ( is => "ro", isa => "Int" );
has organization_name   => ( is => "ro", isa => "Str" );
has room_id             => ( is => "ro", isa => "Int" );
has skype               => ( is => "ro", isa => "Str" );
has tel_extension       => ( is => "ro", isa => "Str" );
has tel_mobile          => ( is => "ro", isa => "Str" );
has tel_organization    => ( is => "ro", isa => "Str" );
has title               => ( is => "ro", isa => "Str" );
has twitter             => ( is => "ro", isa => "Str" );
has url                 => ( is => "ro", isa => "Str" );

sub room {
    my $self = shift;
    return $self->ds->relationship( "room" )->retrieve( $self->room_id );
}

sub rooms {
    my $self = shift;
    return $self->ds->relationship( "room" )->search( @_ );
}

1;
