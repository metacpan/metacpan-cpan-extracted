#############################################################################
## Name:        lib/Wx/DemoModules/wxMDI.pm
## Purpose:     MDI (Multiple Document Interface) demo
## Author:      Mattia Barbon
## Modified by:
## Created:     17/09/2001
## RCS-ID:      $Id: wxMDI.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2005, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::MDI;

package Wx::DemoModules::wxMDI;

use strict;
use base qw(Wx::MDIParentFrame);

use Wx qw(:misc :textctrl :window :frame wxID_CLOSE);
use Wx::Event qw(EVT_MENU EVT_CLOSE EVT_SIZE);

my( $ID_CREATE_CHILD, ) =
  ( 2000 .. 3000 );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new
      ( $parent, -1, 'wxPerl MDI demo',  wxDefaultPosition, wxDefaultSize,
        wxDEFAULT_FRAME_STYLE|wxHSCROLL|wxVSCROLL|wxNO_FULL_REPAINT_ON_RESIZE);

    my $file = Wx::Menu->new;
    $file->Append( $ID_CREATE_CHILD, "Create a new child" );
    $file->AppendSeparator;
    $file->Append( wxID_CLOSE, "Close frame" );

    $self->{help} = new Wx::TextCtrl($self, -1, "A help Window",
                                     wxDefaultPosition, wxDefaultSize,
                                     wxTE_MULTILINE | wxSUNKEN_BORDER);

    my $bar = Wx::MenuBar->new;
    $bar->Append( $file, "File" );

    $self->SetMenuBar( $bar );

    EVT_MENU( $self, $ID_CREATE_CHILD, \&OnCreateChild );
    EVT_MENU( $self, wxID_CLOSE, sub { $_[0]->Close } );
    EVT_SIZE( $self, \&OnSize );

    $self->SetSize( 500, 400 );

    return $self;
}

sub OnCreateChild {
    my( $self, $event ) = @_;

    my $child = Wx::MDIChildFrame->new( $self, -1, "I'm a child" );
    $child->SetIcon( Wx::GetWxPerlIcon );

    my $file = Wx::Menu->new;
    $file->Append( $ID_CREATE_CHILD, "Create a new child" );
    $file->AppendSeparator;
    $file->Append( wxID_CLOSE, "Close child" );

    my $bar = Wx::MenuBar->new;
    $bar->Append( $file, "File" );

    $child->SetMenuBar( $bar );

    EVT_MENU( $child, wxID_CLOSE, sub { $_[0]->Close } );

    $child->Show;
}

sub OnSize {
    my( $self, $event ) = @_;

    my( $x, $y ) = $self->GetClientSizeXY();
    my $client_window = $self->GetClientWindow();
    $client_window->SetSize( 200, 0, $x - 200, $y);
    $self->{help}->SetSize( 0, 0, 200, $y);

    $event->Skip;
}

sub add_to_tags { qw(managed) }
sub title { 'MDI' }

1;

