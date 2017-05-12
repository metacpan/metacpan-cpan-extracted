#############################################################################
## Name:        lib/Wx/DemoModules/wxPopupWindow.pm
## Purpose:     wxPerl demo helper for Wx::PopupWindow
## Author:      Mattia Barbon
## Modified by:
## Created:     25/09/2006
## RCS-ID:      $Id: wxPopupWindow.pm 2772 2010-02-01 14:23:16Z mdootson $
## Copyright:   (c) 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxPopupWindow;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx qw(:progressdialog);
use Wx::Event qw(EVT_BUTTON);

__PACKAGE__->mk_accessors( qw(popup) );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );

    my $popup        = Wx::Button->new( $self, -1, 'Popup',     [ 100, 10 ] );
    my $popdown      = Wx::Button->new( $self, -1, 'Popdown',   [ 100, 40 ] );
    

    EVT_BUTTON( $self, $popup, \&on_popup );
    EVT_BUTTON( $self, $popdown, \&on_popdown );
    
    unless( Wx::wxMAC() ) {
        # not implemented on Mac
        my $poptransient = Wx::Button->new( $self, -1, 'Transient', [ 100, 70 ] );
        EVT_BUTTON( $self, $poptransient, \&on_poptransient );
    }
    

    return $self;
}

sub on_popup {
    my( $self, $event ) = @_;

    my $popup = Wx::DemoModules::wxPopupWindow::Custom->new( $self );
    $popup->Move( 200, 200 );
    $popup->SetSize( 300, 200 );
    $popup->Show;

    $self->popup( $popup );
}

sub on_popdown {
    my( $self, $event ) = @_;

    return unless $self->popup;
    my $popup = $self->popup;
    $self->popup( undef );

    $popup->Hide;
    $popup->Destroy;
}

sub on_poptransient {
    my( $self, $event ) = @_;

    my $popup = Wx::DemoModules::wxPopupWindow::TransientCustom->new( $self );
    $popup->Move( 200, 200 );
    $popup->SetSize( 300, 200 );
    $popup->Popup;
}

sub add_to_tags { qw(managed) }
sub title { 'wxPopupWindow' }

package Wx::DemoModules::wxPopupWindow::Custom;

use strict;
use base qw(Wx::PopupWindow);

use Wx qw(wxSOLID);
use Wx::Event qw(EVT_PAINT);

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    EVT_PAINT( $self, \&on_paint );

    return $self;
}

sub on_paint {
    my( $self, $event ) = @_;
    my $dc = Wx::PaintDC->new( $self );

    $dc->SetBrush( Wx::Brush->new( Wx::Colour->new( 0, 192, 0 ), wxSOLID ) );
    $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 0, 0, 0 ), 1, wxSOLID ) );
    $dc->DrawRectangle( 0, 0, $self->GetSize->x, $self->GetSize->y );
}

package Wx::DemoModules::wxPopupWindow::TransientCustom;

use strict;
use base qw(Wx::PlPopupTransientWindow);

use Wx qw(wxSOLID);
use Wx::Event qw(EVT_PAINT);

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    EVT_PAINT( $self, \&on_paint );

    return $self;
}

sub ProcessLeftDown {
    Wx::LogMessage( 'ProcessLeftDown' );
    return 0;
}

sub on_paint {
    my( $self, $event ) = @_;
    my $dc = Wx::PaintDC->new( $self );

    $dc->SetBrush( Wx::Brush->new( Wx::Colour->new( 192, 0, 0 ), wxSOLID ) );
    $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 0, 0, 0 ), 1, wxSOLID ) );
    $dc->DrawRectangle( 0, 0, $self->GetSize->x, $self->GetSize->y );
}

1;
