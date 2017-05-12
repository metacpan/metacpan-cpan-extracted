#############################################################################
## Name:        lib/Wx/DemoModules/wxGraphicsContext.pm
## Purpose:     wxPerl demo helper for Wx::GraphicsContext
## Author:      Mattia Barbon
## Modified by:
## Created:     07/10/2007
## RCS-ID:      $Id: wxGraphicsContext.pm 2812 2010-02-20 10:53:40Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxGraphicsContext;

use strict;
use base qw(Wx::Panel);
use Wx qw(wxRED_BRUSH wxBLACK_BRUSH wxNORMAL_FONT wxBLACK wxWINDING_RULE);
use Wx::Event qw(EVT_PAINT);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );

    EVT_PAINT( $self, \&_on_paint );

    return $self;
}

sub _on_paint {
    my( $self, $event ) = @_;
    my $dc = Wx::PaintDC->new( $self );
    my $cxt = Wx::GraphicsContext::Create( $dc );

    my $path = $cxt->CreatePath;

    $path->MoveToPoint( 100.5, 100.5 );
    $path->AddLineToPoint( 150, 150.5 );
    $path->AddCurveToPoint( 170, 170, 120, 180, 100, 200 );
    $path->AddLineToPoint( 50, 150 );
    $path->AddArc( 100, 150, 50, 3/2*3.141, 0, 1 );

    my $brush = $cxt->CreateBrush( wxRED_BRUSH );
    my $font = $cxt->CreateFont( wxNORMAL_FONT );

    $cxt->SetBrush( $brush );

    $cxt->FillPath( $path, wxWINDING_RULE );

    $cxt->SetBrush( wxBLACK_BRUSH );
    $cxt->SetFont( $font );

    $cxt->DrawText( "At pixel", 20, 20, 0 );
    $cxt->DrawText( "At half pixel", 40.5, 40.5, 0 );
    $cxt->DrawText( "At half pixel, rotated", 60.5, 60.5, -3.141/8*3 );
}

sub add_to_tags  { qw(misc) }
sub title { 'wxGraphicsContext' }

defined &Wx::GraphicsContext::Create;
