#############################################################################
## Name:        lib/Wx/DemoModules/wxComboCtrl.pm
## Purpose:     wxPerl demo helper for Wx::ComboCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     22/08/2007
## RCS-ID:      $Id: wxComboCtrl.pm 2812 2010-02-20 10:53:40Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxComboCtrl;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:comboctrl);
use Wx::Event qw();

__PACKAGE__->mk_accessors( qw(comboctrl) );

sub styles {
    my( $self ) = @_;

    return ( [ wxCB_READONLY, 'Read only' ],
             [ wxTE_PROCESS_ENTER, 'Process "Enter"' ],
             [ wxCC_SPECIAL_DCLICK, 'Handle double clicks' ],
             [ wxCC_STD_BUTTON, 'Use push button' ],
             );
}

sub create_control {
    my( $self ) = @_;
    my $comboctrl = Wx::ComboCtrl->new( $self, -1, "Fifth", [-1, -1],
                                        [-1, -1], $self->style );
    my $popup = Wx::DemoModules::wxComboCtrl::Popup->new;

    $comboctrl->SetPopupControl( $popup );

    return $self->comboctrl( $comboctrl );
}

sub add_to_tags { qw(controls) }
sub title { 'wxComboCtrl' }

package Wx::DemoModules::wxComboCtrl::Popup;

use strict;
use base qw(Wx::PlComboPopup);

use Wx::Event qw(EVT_RADIOBOX);

sub Init {
    my( $self ) = @_;

    $self->{value} = "";
}

sub Create {
    my( $self, $parent ) = @_;

    my @choices = qw(First Second Third Fourth Fifth
                     Sixth Seventh Eigth Nineth Tenth);
    my $ctrl = Wx::RadioBox->new( $parent, -1, 'Choose', [-1, -1], [-1, -1],
                                  \@choices, 3 );

    EVT_RADIOBOX( $ctrl, $ctrl,
                  sub {
                      $self->{value} = $_[1]->GetString;
                      $self->Dismiss;
                  } );

    $self->{ctrl} = $ctrl;

    return 1;
}

sub GetControl {
    my( $self ) = @_;

    return $self->{ctrl};
}

sub SetStringValue {
    my( $self, $string ) = @_;

    # save value in case it does not match any of the existing
    $self->{value} = $string;
    $self->{ctrl}->SetStringSelection( $string );
}

sub GetStringValue {
    my( $self ) = @_;

    return $self->{value} if $self->{ctrl}->GetSelection < 0;
    return $self->{ctrl}->GetStringSelection;
}

sub GetAdjustedSize {
    my( $self, $min_width, $pref_height, $max_height ) = @_;

    return $self->{ctrl}->GetBestSize;
}

sub OnPopup {
    my( $self ) = @_;

    Wx::LogMessage( "Popping up" );
}

sub OnDismiss {
    my( $self ) = @_;

    Wx::LogMessage( "Being dismissed" );
}

1;
