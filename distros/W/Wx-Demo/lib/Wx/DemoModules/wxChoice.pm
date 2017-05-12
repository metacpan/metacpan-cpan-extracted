#############################################################################
## Name:        lib/Wx/DemoModules/wxChoice.pm
## Purpose:     wxPerl demo helper for Wx::Choice
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxChoice.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxChoice;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:combobox wxNOT_FOUND);
use Wx::Event qw(EVT_CHOICE);

__PACKAGE__->mk_accessors( qw(choice) );

sub styles {
    my( $self ) = @_;

    return ( [ wxCB_SORT, 'Sorted' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Select item',
               with_value  => 1,
               action      => sub { $self->choice->SetSelection( $_[0] ) },
               },
             { label       => 'Select string',
               with_value  => 1,
               action      => sub { $self->choice
                                      ->SetStringSelection( $_[0] ) },
               },
             { label       => 'Clear',
               action      => sub { $self->choice->Clear },
               },
             { label       => 'Append',
               with_value  => 1,
               action      => sub { $self->choice->Append( $_[0] ) },
               },
             { label       => 'Delete selected item',
               action      => \&on_delete_selected,
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $choices = [ 'This', 'is one of my',
                    'really', 'wonderful', 'examples', ];

    my $choice =  Wx::Choice->new( $self, -1,
                                   [-1, -1], [120, -1], $choices,
                                   $self->style );
    EVT_CHOICE( $self, $choice, \&OnChoice );

    return $self->choice( $choice );
}

sub OnChoice {
    my( $self, $event ) = @_;

    Wx::LogMessage( join '', "Choice event selection string is: '",
                             $event->GetString(), "'" );
    Wx::LogMessage( "Choice control selection string is: '",
                    $self->choice->GetStringSelection(), "'" );
}

sub on_delete_selected {
    my( $self ) = @_;
    my( $idx );

    if( ( $idx = $self->choice->GetSelection() ) != wxNOT_FOUND ) {
        $self->choice->Delete( $idx );
    }
}

sub add_to_tags { qw(controls) }
sub title { 'wxChoice' }

1;
