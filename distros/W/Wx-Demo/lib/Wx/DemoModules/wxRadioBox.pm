#############################################################################
## Name:        lib/Wx/DemoModules/wxRadioBox.pm
## Purpose:     wxPerl demo helper for Wx::RadioBox
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxRadioBox.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxRadioBox;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:radiobox wxNOT_FOUND wxDefaultPosition wxDefaultSize);
use Wx::Event qw(EVT_RADIOBOX);

__PACKAGE__->mk_accessors( qw(radiobox) );

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Select item',
               with_value  => 1,
               action      => sub { $self->radiobox->SetSelection( $_[0] ) },
               },
             { label       => 'Select string',
               with_value  => 1,
               action      => sub { $self->radiobox
                                      ->SetStringSelection( $_[0] ) },
               },
             { label       => 'Set label',
               with_value  => 1,
               action      => sub { $self->radiobox->SetLabel( $_[0] ) },
               },
             { label       => 'Set item label',
               with_value  => 2,
               action      => sub { $self->radiobox
                                      ->SetItemLabel( $_[0], $_[1] ) },
               },
             { label       => 'Disable item',
               with_value  => 1,
               action      => sub { $self->radiobox->EnableItem( $_[0], 0 ) },
               },
             { label       => 'Enable item',
               with_value  => 1,
               action      => sub { $self->radiobox->EnableItem( $_[0], 1 ) },
               },
             { label       => 'Hide item',
               with_value  => 1,
               action      => sub { $self->radiobox->ShowItem( $_[0], 0 ) },
               },
             { label       => 'Show item',
               with_value  => 1,
               action      => sub { $self->radiobox->ShowItem( $_[0], 1 ) },
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $choices = [ "First", "Second", "Third", "Fourth", "Fifth",
                    "Sixth", "Seventh", "Eighth", "Nineth", "Tenth" ];

    my $radiobox = Wx::DemoModules::wxRadioBox::Custom->new
      ( $self, -1, "Radio box", [-1, -1],
        wxDefaultSize, $choices, 3, wxRA_SPECIFY_COLS );

    EVT_RADIOBOX( $self, $radiobox, \&OnRadio );

    return $self->radiobox( $radiobox );
}

sub OnRadio {
    my( $self, $event ) = @_;

    Wx::LogMessage( join '', "RadioBox selection string is: ",
                              $event->GetString() );
}

sub add_to_tags { qw(controls) }
sub title { 'wxRadioBox' }

package Wx::DemoModules::wxRadioBox::Custom;

use strict;
use base qw(Wx::RadioBox);

use Wx::Event qw(EVT_SET_FOCUS EVT_KILL_FOCUS);

sub new {
    my( $class ) = shift;
    my( $self ) = $class->SUPER::new( @_ );

    EVT_SET_FOCUS( $self, \&OnFocusGot );
    EVT_KILL_FOCUS( $self, \&OnFocusLost );

    return $self;
}

sub OnFocusGot {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Wx::DemoModules::wxRadioBox::Custom::OnFocusGot' );
    $event->Skip();
}

sub OnFocusLost {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Wx::DemoModules::wxRadioBox::Custom::OnFocusLost' );
    $event->Skip();
}

1;
