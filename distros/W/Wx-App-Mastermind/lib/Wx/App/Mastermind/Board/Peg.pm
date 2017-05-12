package Wx::App::Mastermind::Board::Peg;

use strict;
use warnings;

use Wx qw(wxSOLID wxTRANSPARENT_BRUSH wxBLACK_PEN);

my %colors =
  ( K => Wx::Colour->new( 0x00, 0x00, 0x00 ),
    B => Wx::Colour->new( 0x00, 0x00, 0xff ),
    G => Wx::Colour->new( 0x00, 0xff, 0x00 ),
    R => Wx::Colour->new( 0xff, 0x00, 0x00 ),
    Y => Wx::Colour->new( 0xff, 0xff, 0x00 ),
    W => Wx::Colour->new( 0xff, 0xff, 0xff ),
    );

sub draw {
    my( $self, $dc, $x, $y, $width, $height, $peg, $selected ) = @_;

    $dc->SetPen( wxBLACK_PEN );
    if( $peg eq ' ' ) {
        $dc->SetBrush( wxTRANSPARENT_BRUSH );
        $dc->DrawRectangle( $x, $y, $width, $height );
    } else {
        $dc->SetBrush( Wx::Brush->new( $colors{$peg}, wxSOLID ) );
        $dc->DrawRectangle( $x, $y, $width, $height );
    }

    if( $selected ) {
        $dc->SetBrush( wxTRANSPARENT_BRUSH );
        $dc->DrawRectangle( $x - 2, $y - 2, $width + 4, $height + 4 );
    }
}

1;
