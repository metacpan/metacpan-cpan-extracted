#############################################################################
## Name:        lib/Wx/DemoModules/wxSpinCtrl.pm
## Purpose:     wxPerl demo helper for Wx::SpinCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxSpinCtrl.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxSpinCtrl;

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
               );
}

sub create_control {
    my( $self ) = @_;

    my $spinctrl = Wx::SpinCtrl->new( $self, -1, 0, [-1, -1], [-1, -1],
                                      $self->style );
    $spinctrl->SetRange( 10, 30 );
    $spinctrl->SetValue( 15 );

    EVT_SPINCTRL( $self, $spinctrl, \&OnSpinCtrl );

    return $self->spinctrl( $spinctrl );
}

sub OnSpinCtrl {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Spin ctrl changed: now %d (from event %d)",
                    $self->spinctrl->GetValue,
                    $event->GetInt );
}

sub add_to_tags { qw(controls) }
sub title { 'wxSpinCtrl' }

1;
