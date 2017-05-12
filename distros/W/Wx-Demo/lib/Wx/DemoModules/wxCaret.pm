#############################################################################
## Name:        lib/Wx/DemoModules/wxCaret.pm
## Purpose:     wxPerl demo helper for Wx::Caret
## Author:      Mattia Barbon
## Modified by:
## Created:     12/01/2001
## RCS-ID:      $Id: wxCaret.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2004, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxCaret;

use strict;
use base qw(Wx::ScrolledWindow Class::Accessor::Fast);

use Wx qw(:font :window :keycode wxWHITE wxNORMAL_FONT wxDefaultPosition
          wxDefaultSize wxSOLID);
use Wx::Event qw(EVT_SIZE EVT_PAINT EVT_CHAR);

__PACKAGE__->mk_accessors( qw(text font xchars ychars char_width char_height
                              xmargin ymargin xcaret ycaret) );

sub CharAt {
    my( $this, $x, $y, $char ) = @_;
    my $pos = $x + $y * $this->xchars;

    if( defined $char ) {
        return substr( $this->{text}, $pos, 1 ) = $char;
    } else {
        return substr( $this->{text}, $pos, 1 );
    }
}

# caret motion helpers
sub Home {
    $_[0]->xcaret( 0 );
}

sub End {
    $_[0]->xcaret( $_[0]->xchars - 1 );
}

sub FirstLine {
    $_[0]->ycaret( 0 );
}

sub LastLine {
    $_[0]->ycaret( $_[0]->ychars - 1 );
}

sub PrevChar {
    if( !$_[0]->{xcaret}-- ) {
        $_[0]->End;
        $_[0]->PrevLine;
    }
}

sub NextChar {
    if( ++$_[0]->{xcaret} == $_[0]->xchars ) {
        $_[0]->Home;
        $_[0]->NextLine;
    }
}

sub PrevLine {
    if( !$_[0]->{ycaret}-- ) {
        $_[0]->LastLine;
    }
}

sub NextLine {
    if( ( ++$_[0]->{ycaret} ) == $_[0]->ychars ) {
        $_[0]->FirstLine;
    }
}

sub new {
    my( $class, $parent ) = @_;
    my $this = $class->SUPER::new( $parent, -1, wxDefaultPosition,
                                   wxDefaultSize, wxSUNKEN_BORDER );

    $this->SetBackgroundColour( wxWHITE );
    $this->font( Wx::Font->new( 14, wxMODERN, wxNORMAL, wxNORMAL ) );

    my $dc = Wx::ClientDC->new( $this );
    $dc->SetFont( $this->font );
    $this->char_width( $dc->GetCharWidth );
    $this->char_height( $dc->GetCharHeight );

    my $caret = Wx::Caret->new( $this, $this->char_width, $this->char_height );
    $this->SetCaret( $caret );

    $this->xmargin( 5 );
    $this->ymargin( 5 );
    $this->xcaret( 0 );
    $this->ycaret( 0 );
    $caret->Move( $this->xmargin, $this->ymargin );
    $caret->Show;

    EVT_SIZE( $this, \&OnSize );
    EVT_PAINT( $this, \&OnPaint );
    EVT_CHAR( $this, \&OnChar );

    return $this;
}

sub OnChar {
    my( $this, $event ) = @_;

    {
        my $t = $event->GetKeyCode;

        $t == WXK_LEFT   && do { $this->PrevChar, last };
        $t == WXK_RIGHT  && do { $this->NextChar, last };
        $t == WXK_UP     && do { $this->PrevLine, last };
        $t == WXK_DOWN   && do { $this->NextLine, last };
        $t == WXK_HOME   && do { $this->Home, last };
        $t == WXK_END    && do { $this->End, last };
        $t == WXK_RETURN && do { $this->Home, $this->NextLine, last };

        if( $event->AltDown ) {
            $event->Skip;
            last;
        }

        my $ch = chr $event->GetKeyCode;
        $this->CharAt( $this->xcaret, $this->ycaret, $ch );

        my $suspend = Wx::CaretSuspend->new( $this );
        my $dc = Wx::ClientDC->new( $this );
        $dc->SetFont( $this->font );
        $dc->SetBackgroundMode( wxSOLID );
        $dc->DrawText( $ch, $this->xmargin + $this->xcaret * $this->char_width,
                       $this->ymargin + $this->ycaret * $this->char_height );

        $this->NextChar;
    }

    $this->DoMoveCaret;
    $this->Refresh;
}

sub OnSize {
    my( $this, $event ) = @_;

    # resize and clear underlying buffer
    $this->xchars( int( ( $event->GetSize->x - 2 * $this->xmargin ) /
                        $this->char_width ) || 1 );
    $this->ychars( int( ( $event->GetSize->y - 2 * $this->ymargin ) /
                        $this->char_height ) || 1 );
    $this->text( ' ' x ( $this->xchars * $this->ychars ) );

    Wx::LogMessage( 'Panel size is ( %d, %d)', $this->xchars, $this->ychars );

    $event->Skip;
}

sub OnPaint {
    my( $this, $event ) = @_;

    my $suspend = Wx::CaretSuspend->new( $this );
    my $dc = Wx::PaintDC->new( $this );
    $this->PrepareDC( $dc );
    $dc->Clear;
    $dc->SetFont( $this->font );

    foreach my $y ( 0 .. ( $this->ychars - 1 ) ) {
        $dc->DrawText( substr( $this->{text}, $y * $this->xchars, $this->xchars ),
                       $this->xmargin,
                       $this->ymargin + $y * $this->char_height );
    }
}

sub DoMoveCaret {
    my( $this ) = @_;

    Wx::LogStatus( 'Caret is at ( %d, %d )', $this->xcaret, $this->ycaret );

    $this->GetCaret->Move( $this->xmargin + $this->xcaret * $this->char_width,
                           $this->ymargin + $this->ycaret * $this->char_height );
}

sub add_to_tags { qw(misc) }
sub title { 'wxCaret' }

1;
