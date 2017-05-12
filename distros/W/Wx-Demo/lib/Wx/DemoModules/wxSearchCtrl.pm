#############################################################################
## Name:        lib/Wx/DemoModules/wxSearchCtrl.pm
## Purpose:     wxPerl demo helper for Wx::SearchCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     23/08/2007
## RCS-ID:      $Id: wxSearchCtrl.pm 2812 2010-02-20 10:53:40Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxSearchCtrl;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:textctrl);
use Wx::Event qw(EVT_SEARCHCTRL_SEARCH_BTN EVT_SEARCHCTRL_CANCEL_BTN
                 EVT_TEXT_ENTER);

__PACKAGE__->mk_accessors( qw(search) );

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Show search button',
               action      => sub { $self->search->ShowSearchButton( 1 ) },
               },
             { label       => 'Hide search button',
               action      => sub { $self->search->ShowSearchButton( 0 ) },
               },
             { label       => 'Show cancel button',
               action      => sub { $self->search->ShowCancelButton( 1 ) },
               },
             { label       => 'Hide cencel button',
               action      => sub { $self->search->ShowCancelButton( 0 ) },
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $search = Wx::SearchCtrl->new( $self, -1, '', [-1, -1], [-1, -1],
                                      wxTE_PROCESS_ENTER );

    EVT_SEARCHCTRL_SEARCH_BTN( $self, $search, \&OnSearch );
    EVT_SEARCHCTRL_CANCEL_BTN( $self, $search, \&OnCancel );
    EVT_TEXT_ENTER( $self, $search, \&OnSearchEnter );

    return $self->search( $search );
}

sub OnSearch {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Searching '%s'", $self->search->GetValue );
}

sub OnSearchEnter {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Searching '%s' by 'enter'", $self->search->GetValue );
}

sub OnCancel {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Search cancelled' );
}

sub add_to_tags { qw(controls) }
sub title { 'wxSearchCtrl' }

defined &Wx::SearchCtrl::new ? 1 : 0;
