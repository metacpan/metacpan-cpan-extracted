#############################################################################
## Name:        lib/Wx/DemoModules/wxXrc.pm
## Purpose:     wxWidgets' XML Resources demo
## Author:      Mattia Barbon
## Modified by: Scott Lanning, 11/09/2002
## Created:     12/09/2001
## RCS-ID:      $Id: wxXrc.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2004, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::XRC;

package Wx::DemoModules::wxXrc;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx::Event qw(EVT_BUTTON EVT_MENU);

__PACKAGE__->mk_ro_accessors( qw(xrc) );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );

    # load XRC file
    $self->{xrc} = Wx::XmlResource->new();
    $self->xrc->InitAllHandlers();
    $self->xrc->Load( Wx::Demo->get_data_file( 'xrc/resource.xrc' ) );

    # basic layout
    my $but_frame = Wx::Button->new( $self, -1, 'Load frame', [10, 10] );
    my $but_dialog = Wx::Button->new( $self, -1, 'Load dialog', [150, 10] );

    EVT_BUTTON( $self, $but_frame, \&show_frame );
    EVT_BUTTON( $self, $but_dialog, \&show_dialog );

    return $self;
}

sub show_frame {
    my( $self ) = @_;

    my $frame = Wx::Frame->new
      ( undef, -1, 'XML resources demo', [50, 50], [450, 340] );
    my $menubar = $self->xrc->LoadMenuBar( 'mainmenu' );
    my $toolbar = $self->xrc->LoadToolBar( $self, 'toolbar' );

    $frame->SetMenuBar( $menubar );
    $frame->SetToolBar( $toolbar );

    EVT_MENU( $frame, Wx::XmlResource::GetXRCID( 'menu_quit' ),
              sub { $frame->Close } );
    EVT_MENU( $frame, Wx::XmlResource::GetXRCID( 'menu_dlg1' ),
              sub { $self->show_dialog( $frame, undef ) } );

    $frame->Show;
}

sub show_dialog {
    my( $self, $event, $parent ) = @_;

    my $dialog = $self->xrc->LoadDialog( $parent || $self, 'dlg1' );
    $dialog->ShowModal;
    $dialog->Destroy;
}

sub add_to_tags { qw(misc/xrc) }
sub title { 'Simple' }

1;
