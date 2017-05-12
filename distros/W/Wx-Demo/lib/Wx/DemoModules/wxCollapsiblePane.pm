#############################################################################
## Name:        lib/Wx/DemoModules/wxCollapsiblePane.pm
## Purpose:     wxPerl demo helper for Wx::CollapsiblePane
## Author:      Mattia Barbon
## Modified by:
## Created:     23/08/2007
## RCS-ID:      $Id: wxCollapsiblePane.pm 2812 2010-02-20 10:53:40Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxCollapsiblePane;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:sizer);
use Wx::Event qw(EVT_COLLAPSIBLEPANE_CHANGED);

__PACKAGE__->mk_accessors( qw(pane) );

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Collapse',
               action      => sub { $self->pane->Collapse },
               },
             { label       => 'Expand',
               action      => sub { $self->pane->Expand },
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $pane = Wx::CollapsiblePane->new( $self, -1, 'The pane' );
    my $window = $pane->GetPane;
    my $sz = Wx::BoxSizer->new( wxVERTICAL );

    my $btn = Wx::Button->new( $window, -1, 'A button' );
    my $list = Wx::ListBox->new( $window, -1, [-1, -1], [-1, -1],
                                 [ qw(A list of many different values) ] );

    $sz->Add( $list, 1, wxGROW|wxALL, 5 );
    $sz->Add( $btn, 1, wxGROW|wxALL, 5 );

    $window->SetSizer( $sz );
    $sz->SetSizeHints( $window );

    EVT_COLLAPSIBLEPANE_CHANGED( $self, $pane, \&OnPaneChanged );

    return $self->pane( $pane );
}

sub OnPaneChanged {
    my( $self, $event ) = @_;

    $self->control_sizer->Layout;

    Wx::LogMessage( $event->GetCollapsed ? 'Collapsed' : 'Expanded' );
}

sub add_to_tags { qw(controls) }
sub title { 'wxCollapsiblePane' }

defined &Wx::CollapsiblePane::new ? 1 : 0;
