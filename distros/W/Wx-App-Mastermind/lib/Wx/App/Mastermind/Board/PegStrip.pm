package Wx::App::Mastermind::Board::PegStrip;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Wx qw(wxSOLID wxTRANSPARENT_BRUSH wxBLACK_PEN);

use Wx::App::Mastermind::Board::Peg;

__PACKAGE__->mk_ro_accessors( qw(peg_width peg_height peg_padding) );

sub draw {
    my( $self, $dc, $sx, $y, $pegs, $selected, $current ) = @_;
    my $delta = $self->peg_width + $self->peg_padding;
    my $x = $sx;

    $selected ||= '';
    foreach my $peg ( @$pegs ) {
        Wx::App::Mastermind::Board::Peg->draw
            ( $dc, $x, $y,
              $self->peg_width, $self->peg_height,
              $peg, $peg eq $selected );
        $x += $delta;
    }

    if( $current ) {
        $dc->SetPen( wxBLACK_PEN );
        $dc->SetBrush( wxTRANSPARENT_BRUSH );
        $dc->DrawRectangle( $sx - 2, $y - 2,
                            $delta * @$pegs + 4 - $self->peg_padding,
                            $self->peg_height + 4 );
    }
}

sub get_size {
    my( $self, $peg_count ) = @_;

    return ( ( $self->peg_width + $self->peg_padding ) * $peg_count -
               $self->peg_padding,
             $self->peg_height );
}

sub hit_test {
    my( $self, $x, $y, $peg_count, $mx, $my ) = @_;
    my( $sx, $sy ) = $self->get_size( $peg_count );

    return -1 if    $my < $y || $my > $y + $sy
                 || $mx < $x || $mx > $x + $sx;
    my $delta = $self->peg_width + $self->peg_padding;
    my $hole  = int( ( $mx - $x ) / $delta );

    return $hole if $mx - $x <= $hole * $delta + $self->peg_width;
    return -1;
}

1;
