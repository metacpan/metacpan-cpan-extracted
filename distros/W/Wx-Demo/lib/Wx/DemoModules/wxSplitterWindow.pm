#############################################################################
## Name:        lib/Wx/DemoModules/wxSplitterWindow.pm
## Purpose:     wxPerl demo helper for Wx::SplitterWindow
## Author:      Mattia Barbon
## Modified by:
## Created:     23/08/2006
## RCS-ID:      $Id: wxSplitterWindow.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxSplitterWindow;

use strict;
use base qw(Wx::SplitterWindow Class::Accessor::Fast);

use Wx qw(:splitterwindow wxDefaultPosition wxDefaultSize);
use Wx::Event qw(EVT_SPLITTER_SASH_POS_CHANGED EVT_SPLITTER_SASH_POS_CHANGING
                 EVT_SPLITTER_UNSPLIT EVT_MENU);

__PACKAGE__->mk_accessors( qw(left_window right_window) );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new
      ( $parent, -1, wxDefaultPosition, wxDefaultSize,
        wxSP_3D|wxSP_LIVE_UPDATE );
    my $top = Wx::GetTopLevelParent( $parent );

    EVT_SPLITTER_SASH_POS_CHANGED( $self, $self, \&on_sash_pos_change );
    EVT_SPLITTER_SASH_POS_CHANGING( $self, $self, \&on_sash_pos_changing );
    EVT_SPLITTER_UNSPLIT( $self, $self, sub { Wx::LogMessage( 'Unsplit' ) } );

    my $filemenu = Wx::Menu->new;
    EVT_MENU( $top, $filemenu->Append( -1, "Split vertically" ),
              sub { $self->split_vertically } );
    EVT_MENU( $top, $filemenu->Append( -1, "Split horizontally" ),
              sub { $self->split_horizontally } );
    EVT_MENU( $top, $filemenu->Append( -1, "Unsplit" ),
              sub { $self->unsplit } );
    $filemenu->AppendSeparator;
    EVT_MENU( $top, $filemenu->Append( -1, "Set minimum size" ),
              sub { $self->set_minimum_size } );

    $self->left_window( Wx::TextCtrl->new( $self, -1, 'Left pane' ) );
    $self->right_window( Wx::StaticText->new( $self, -1, 'Right pane' ) );
    $self->Initialize( $self->left_window );
    $self->right_window->Hide;

    $self->{menu} = [ '&Splitter', $filemenu ];

    return $self;
}

sub on_sash_pos_change {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Final sash position = %d', $event->GetSashPosition );
}

sub on_sash_pos_changing {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Current sash position = %d', $event->GetSashPosition );
}

sub split_horizontally {
    my( $self, $event ) = @_;

    $self->Unsplit if $self->IsSplit;
    $self->left_window->Show;
    $self->right_window->Show;
    $self->SplitHorizontally( $self->left_window, $self->right_window );
}

sub split_vertically {
    my( $self, $event ) = @_;

    $self->Unsplit if $self->IsSplit;
    $self->left_window->Show;
    $self->right_window->Show;
    $self->SplitVertically( $self->left_window, $self->right_window );
}

sub set_minimum_size {
    my( $self, $event ) = @_;

    my $size = Wx::GetNumberFromUser( 'Enter minimal size for panes:',
                                      '', '', $self->GetMinimumPaneSize,
                                      0, 10000, $self );

    return if $size == -1;
    $self->SetMinimumPaneSize( $size );
}

sub unsplit {
    my( $self, $event ) = @_;

    $self->Unsplit if $self->IsSplit;
}

sub menu { @{$_[0]->{menu}} }
sub add_to_tags { qw(windows) }
sub title { 'wxSplitterWindow' }

1;
