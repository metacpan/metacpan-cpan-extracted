#############################################################################
## Name:        lib/Wx/DemoModules/wxSpinCtrlDouble.pm
## Purpose:     wxPerl demo helper for Wx::SpinCtrlDouble
## Author:      Mattia Barbon
## Modified by:
## Created:     20/02/2010
## RCS-ID:      $Id: wxSpinCtrlDouble.pm 2920 2010-04-29 21:11:27Z mbarbon $
## Copyright:   (c) 2010 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxSpinCtrlDouble;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:spinctrl);
use Wx::Event qw(EVT_SPINCTRL EVT_SPIN EVT_SPIN_DOWN EVT_SPIN_UP);

__PACKAGE__->mk_accessors( qw(spinctrl) );

sub styles {
    my( $self ) = @_;

    return ( [ wxSP_ARROW_KEYS, 'Allow arrow keys' ],
             [ wxSP_WRAP, 'Wrap' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { with_value  => 1,
               label       => 'Set Value',
               action      => sub { $self->spinctrl->SetValue( $_[0] ) },
               },
             { with_value  => 2,
               label       => 'Set Range',
               action      => sub { $self->spinctrl->SetRange( $_[0], $_[1] ) },
               },
             { with_value  => 1,
               label       => 'Set Increment',
               action      => sub { $self->spinctrl->SetIncrement( $_[0] ) },
               },
             { with_value  => 1,
               label       => 'Set Decimals',
               action      => sub { $self->spinctrl->SetDigits( $_[0] ) },
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $spinctrl = Wx::SpinCtrlDouble->new( $self, -1, 0, [-1, -1], [-1, -1],
                                            $self->style );
    $spinctrl->SetRange( 7.3, 20.4 );
    $spinctrl->SetValue( 15.2 );
    $spinctrl->SetIncrement( 0.1 );
    $spinctrl->SetDigits( 1 );

    EVT_SPINCTRL( $self, $spinctrl, \&OnSpinCtrl );

    return $self->spinctrl( $spinctrl );
}

sub OnSpinCtrl {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Spin ctrl changed: now %d (from event %d)",
                    $self->spinctrl->GetValue,
                    $event->GetInt );
}

sub add_to_tags { ( Wx::wxVERSION() >= 2.009 ) ? qw(controls new) : () }
sub title { 'wxSpinCtrlDouble' }

1;
