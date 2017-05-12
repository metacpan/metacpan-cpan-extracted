package Wx::App::Mastermind::Board::Editor;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Wx::App::Mastermind::Board::PegStrip;

__PACKAGE__->mk_accessors( qw(selected_peg enabled) );
__PACKAGE__->mk_ro_accessors( qw(position board) );

sub draw {
    my( $self, $dc ) = @_;

    my $strip = $self->board->_create_strip;
    $strip->draw( $dc, $self->position->[0],
                  $self->position->[1], $self->pegs, $self->selected_peg );
}

sub on_click {
    my( $self, $event ) = @_;
    return unless $self->enabled;
    my $hit = $self->board->hit_test( $event->GetPositionXY );

    return unless $hit;
    if( $hit->[0] eq 'editor' ) {
        $self->selected_peg( $self->pegs->[$hit->[1]] );
        $self->board->Refresh;
    } elsif( $hit->[0] eq 'move' ) {
        return unless $self->selected_peg;
        return if $hit->[1] > $self->board->position;
        $self->board->set_peg( $hit->[1], $hit->[2], $self->selected_peg );
    }
}

sub on_move {
    my( $self ) = @_;
    return unless $self->enabled;
    my $move = $self->board->moves( $self->board->position );
    return if grep / /, @$move;
    $self->board->add_move( $move );
}

sub get_size {
    my( $self ) = @_;
    my $strip = $self->board->_create_strip;

    return $strip->get_size( $self->peg_count );
}

sub hit_test {
    my( $self, $mx, $my ) = @_;
    my $strip = $self->board->_create_strip;

    return $strip->hit_test( $self->position->[0], $self->position->[1],
                             $self->peg_count, $mx, $my );
}

sub pegs { $_[0]->board->pegs }
sub peg_count { scalar @{$_[0]->pegs} }

1;
