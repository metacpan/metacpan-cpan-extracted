#############################################################################
## Name:        lib/Wx/DemoModules/wxSpinButton.pm
## Purpose:     wxPerl demo helper for Wx::SpinButton
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxSpinButton.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxSpinButton;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:spinbutton :sizer wxNOT_FOUND);
use Wx::Event qw(EVT_SPIN EVT_SPIN_UP EVT_SPIN_DOWN);

__PACKAGE__->mk_accessors( qw(spinbutton value) );

sub styles {
    my( $self ) = @_;

    return ( [ wxSP_HORIZONTAL, 'Horizontal' ],
             [ wxSP_VERTICAL, 'Vertical' ],
             [ wxSP_ARROW_KEYS, 'Allow arrow keys' ],
             [ wxSP_WRAP, 'Wrap' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { with_value  => 1,
               label       => 'Set Value',
               action      => sub { $self->spinbutton->SetValue( $_[0] ) },
               },
             { with_value  => 2,
               label       => 'Set Range',
               action      => sub {
                   $self->spinbutton->SetRange( $_[0], $_[1] )
               },
               },
               );
}

sub add_commands {
    my( $self, $sizer ) = @_;

    $self->SUPER::add_commands( $sizer );

    my $sz = Wx::BoxSizer->new( wxHORIZONTAL );
    $sz->Add( Wx::StaticText->new( $self, -1, 'Value' ), 1, wxALL, 3 );
    $sz->Add( $self->value( Wx::TextCtrl->new( $self, -1, '' ) ), 1, wxALL, 3 );

    $sizer->Add( $sz, 0, wxGROW );
}

sub create_control {
    my( $self ) = @_;

    my $spinbutton = Wx::SpinButton->new( $self, -1, [-1, -1], [-1, -1],
                                          $self->style );
    $spinbutton->SetRange( -10, 30 );
    $spinbutton->SetValue( -5 );

    EVT_SPIN( $self, $spinbutton, \&OnSpinUpdate );
    EVT_SPIN_UP( $self, $spinbutton, \&OnSpinUp );
    EVT_SPIN_DOWN( $self, $spinbutton, \&OnSpinDown );

    return $self->spinbutton( $spinbutton );
}

sub OnSpinUp {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Spin control up: current = %d",
                    $self->spinbutton->GetValue );

    if( $self->spinbutton->GetValue > 17 ) {
        Wx::LogMessage( "Preventing the spin button from going above 17" );
        $event->Veto;
    }
}

sub OnSpinDown {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Spin control down: current = %d",
                    $self->spinbutton->GetValue );

    if( $self->spinbutton->GetValue < -17 ) {
        Wx::LogMessage( "Preventing the spin button from going below -17" );
        $event->Veto;
    }
}

sub OnSpinUpdate {
    my( $self, $event ) = @_;

    $self->value->SetValue( $event->GetPosition );
    Wx::LogMessage( "Spin control range: ( %d, %d ) current = %d",
                    $self->spinbutton->GetMin,
                    $self->spinbutton->GetMax,
                    $self->spinbutton->GetValue );
}

sub add_to_tags { qw(controls) }
sub title { 'wxSpinButton' }

1;
