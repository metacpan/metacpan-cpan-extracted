package Wx::App::Mastermind::Player::Computer;

use strict;
use warnings;
use base qw(Wx::Perl::Thread::ClassPublisher Wx::App::Mastermind::Player);

use Games::Mastermind::Solver::BruteForce;

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new;
    $self->Wx::App::Mastermind::Player::init( @args );

    return $self;
}

sub moves_editable { 0 }
sub answers_editable { 0 }

sub play {
    my( $self ) = @_;

    $self->listener->guess;
}

sub got_guess {
    my( $self, $itme, $event, $guess ) = @_;

    $self->add_move( $guess );
}

sub got_answer {
    my( $self, $item, $event, $answer ) = @_;

    $self->add_answer( $answer );
    $self->turn_finished;
}

sub create_listener {
    my( $self, $game ) = @_;
    my $listener = Wx::App::Mastermind::Player::ComputerListener->create( $game, $self );

    $self->add_subscriber( 'guessed', $self, 'got_guess' );
    $self->add_subscriber( 'answered', $self, 'got_answer' );

    return $listener;
}

# screw multiple inheritance...
sub notify_subscribers {
    shift->Wx::Perl::Thread::ClassPublisher::notify_subscribers( @_ );
}

sub terminate {
    my( $self ) = @_;

    $self->listener->wpto_terminate;
    $self->listener->wpto_join;
}

package Wx::App::Mastermind::Player::ComputerListener;

use strict;
use warnings;
use base qw(Class::Accessor::Fast Wx::Perl::Thread::Object);

__PACKAGE__->mk_ro_accessors( qw(solver handler) );

sub new {
    my( $class, $game, $handler ) = @_;
    my $self = $class->SUPER::new
      ( { solver  => Games::Mastermind::Solver::BruteForce->new( $game ),
          handler => $handler } );

    return $self;
}

sub guess {
    my( $self ) = @_;
    my $guess = $self->solver->guess;

    $self->handler->notify_subscribers( 'guessed', $guess );
}

sub on_move {
    my( $self, $item, $event, %params ) = @_;
    my $answer = $self->solver->game->play( @{$params{move}} );

    $self->handler->notify_subscribers( 'answered', $answer );
}

sub on_answer {
    my( $self, $item, $event, %params ) = @_;
    my $guess = $self->solver->game->history->[-1][0];

    $self->solver->check( $guess, $params{answer} );
}

sub reset { $_[0]->solver->reset }

1;
