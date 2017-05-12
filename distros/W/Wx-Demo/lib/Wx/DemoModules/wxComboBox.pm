#############################################################################
## Name:        lib/Wx/DemoModules/wxComboBox.pm
## Purpose:     wxPerl demo helper for Wx::ComboBox
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxComboBox.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxComboBox;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:combobox :textctrl wxNOT_FOUND);
use Wx::Event qw(EVT_COMBOBOX EVT_TEXT EVT_TEXT_ENTER);

__PACKAGE__->mk_accessors( qw(combobox) );

sub styles {
    my( $self ) = @_;

    return ( [ wxCB_SORT, 'Sorted' ],
             [ wxCB_SIMPLE, 'Simple' ],
             [ wxCB_DROPDOWN, 'Dropdown' ],
             [ wxCB_READONLY, 'Read-only' ],
             [ wxTE_PROCESS_ENTER, 'Process enter' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Select item',
               with_value  => 1,
               action      => sub { $self->combobox->SetSelection( $_[0] ) },
               },
             { label       => 'Select string',
               with_value  => 1,
               action      => sub { $self->combobox
                                      ->SetStringSelection( $_[0] ) },
               },
             { label       => 'Clear',
               action      => sub { $self->combobox->Clear },
               },
             { label       => 'Append',
               with_value  => 1,
               action      => sub { $self->combobox->Append( $_[0] ) }
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

    my $combobox = Wx::DemoModules::wxComboBox::Custom->new
        ( $self, -1, "This", [-1, -1], [-1, -1],
          $choices, $self->style );

    EVT_COMBOBOX( $self, $combobox, \&OnCombo );
    EVT_TEXT( $self, $combobox, \&OnComboTextChanged );
    EVT_TEXT_ENTER( $self, $combobox, \&OnComboTextEnter );

    return $self->combobox( $combobox );
}

sub OnCombo {
    my( $self, $event ) = @_;

    Wx::LogMessage( join '', "ComboBox event selection string is: '",
                    $event->GetString(), "'" );
    Wx::LogMessage( "ComboBox control selection string is: '",
                    $self->combobox->GetStringSelection(), "'" );
}

sub OnComboTextChanged {
    my( $self ) = @_;

    Wx::LogMessage( "Text in the combobox changed: now is '%s'.",
                    $self->combobox->GetValue() );
}

sub OnComboTextEnter {
    my( $self ) = @_;

    Wx::LogMessage( "Enter pressed in the combobox changed: now is '%s'.",
                    $self->combobox->GetValue() );
}

sub on_delete_selected {
    my( $self ) = @_;
    my( $idx );

    if( ( $idx = $self->combobox->GetSelection() ) != wxNOT_FOUND ) {
        $self->combobox->Delete( $idx );
    }
}

sub add_to_tags { qw(controls) }
sub title { 'wxComboBox' }

package Wx::DemoModules::wxComboBox::Custom;

use strict;
use base qw(Wx::ComboBox);
use Wx::Event qw(EVT_SET_FOCUS EVT_CHAR EVT_KEY_DOWN EVT_KEY_UP);

sub new {
    my( $class ) = shift;
    my( $self ) = $class->SUPER::new( @_ );

    EVT_SET_FOCUS( $self, \&OnFocusGot );
    EVT_CHAR( $self, \&OnChar );
    EVT_KEY_DOWN( $self, \&OnKeyDown );
    EVT_KEY_UP( $self, \&OnKeyUp );

    return $self;
}

sub OnChar {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Wx::DemoModules::wxComboBox::Custom::OnChar' );

    if( $event->GetKeyCode() == ord( 'w' ) ) {
        Wx::LogMessage( "Wx::DemoModules::wxComboBox::Custom: 'w' ignored" );
    } else {
        $event->Skip();
    }
}

sub OnKeyDown {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Wx::DemoModules::wxComboBox::Custom::OnKeyDown' );

    if( $event->GetKeyCode() == ord( 'w' ) ) {
        Wx::LogMessage( "Wx::DemoModules::wxComboBox::Custom: 'w' ignored" );
    } else {
        $event->Skip();
    }
}

sub OnKeyUp {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Wx::DemoModules::wxComboBox::Custom::OnKeyUp' );
    $event->Skip();
}

sub OnFocusGot {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Wx::DemoModules::wxComboBox::Custom::FocusGot' );
    $event->Skip();
}

1;
