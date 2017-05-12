package Wx::App::Mastermind::Player;

use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Publisher);

use Games::Mastermind;

__PACKAGE__->mk_accessors( qw(board won) );
__PACKAGE__->mk_ro_accessors( qw(listener pegs holes tries) );

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new;

    $self->init( @args );

    return $self;
}

sub init {
    my( $self, %args ) = @_;

    my $game = Games::Mastermind->new( %args );
    $self->{listener} = $self->create_listener( $game );
    $self->{pegs} = $game->pegs;
    $self->{holes} = $game->holes;
    $self->{tries} = $args{tries};
    $self->add_subscriber( 'move', $self->listener, 'on_move' );
    $self->add_subscriber( 'answer', $self->listener, 'on_answer' );

    return $self;
}

sub add_move {
    my( $self, $move ) = @_;

    $self->board->add_move( $move );
}

sub add_answer {
    my( $self, $answer ) = @_;

    $self->won( $answer->[0] == $self->holes );
    $self->board->add_answer( $answer );
}

sub turn_finished {
    my( $self ) = @_;

    $self->board->turn_finished;
}

sub stop {
    my( $self ) = @_;

    $self->board->stop;
}

sub start {
    my( $self ) = @_;

    $self->board->start;
}

sub terminate {}

sub reset {
    my( $self ) = @_;

    $self->board->reset;
    $self->listener->reset;
    $self->won( 0 );
}

1;
