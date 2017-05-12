package Wx::App::Mastermind::Player::Human;

use strict;
use warnings;
use base qw(Wx::App::Mastermind::Player);

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    return $self;
}

sub moves_editable { 1 }
sub answers_editable { 0 }
sub play { }

sub create_listener {
    my( $self, $game ) = @_;

    return Wx::App::Mastermind::Player::HumanListener->new( $game );
}

package Wx::App::Mastermind::Player::HumanListener;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(game) );

sub new {
    my( $class, $game ) = @_;
    my $self = $class->SUPER::new( { game => $game } );

    return $self;
}

sub on_move {
    my( $self, $item, $event, %params ) = @_;
    my $answer = $self->game->play( @{$params{move}} );

    $item->player->add_answer( $answer );
    $item->player->turn_finished;
}

sub on_answer { }
sub reset { $_[0]->game->reset }

1;
