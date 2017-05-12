#############################################################################
## Name:        lib/Wx/DemoModules/wxRadioButton.pm
## Purpose:     wxPerl demo helper for Wx::RadioButton
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxRadioButton.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxRadioButton;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx qw(:radiobutton :font wxDefaultPosition wxDefaultSize);
use Wx::Event qw(EVT_RADIOBUTTON EVT_BUTTON);

__PACKAGE__->mk_ro_accessors( qw(radiobut1_1 radiobut1_2
                                 radiobut2_1 radiobut2_2
                                 radiobut2_3) );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );


    my $b1 = Wx::Button->new( $self, -1, "Select #&1", [180, 30], [140, 30] );
    my $b2 = Wx::Button->new( $self, -1, "&Select #&2",
                              [180, 80], [140, 30] );

    my $rb11 = Wx::RadioButton->new( $self, -1, "Radio&1,1",
                                     [10, 30], wxDefaultSize, wxRB_GROUP );
    my $rb12 = Wx::RadioButton->new( $self, -1, "Radio&1,2",
                                     [10, 70], wxDefaultSize );

    my $rb21 = Wx::RadioButton->new( $self, -1, "Radio&2,1",
                                     [90, 30], wxDefaultSize, wxRB_GROUP );
    my $rb22 = Wx::RadioButton->new( $self, -1, "Radio&2,2",
                                     [90, 70], wxDefaultSize );
    my $rb23 = Wx::RadioButton->new( $self, -1, "Radio&2,3",
                                     [90, 110], wxDefaultSize );

    $rb11->SetValue( 1 );
    $rb21->SetValue( 1 );

    EVT_BUTTON( $self, $b1, \&OnRadioButton_Sel1 );
    EVT_BUTTON( $self, $b2, \&OnRadioButton_Sel2 );
    foreach my $rb ( $rb11, $rb12, $rb21, $rb22, $rb23 ) {
        EVT_RADIOBUTTON( $self, $rb, \&OnRadio );
    }
    @{$self}{qw(radiobut1_1 radiobut1_2
                radiobut2_1 radiobut2_2
                radiobut2_3)} = ( $rb11, $rb12, $rb21, $rb22, $rb23 );

    return $self;
}

sub OnRadio {
    my( $self, $event ) = @_;

    Wx::LogMessage( join '', "RadioButton selection string is: ",
                              $event->GetEventObject->GetLabel );
}

sub OnRadioButton_Sel1 {
    my( $self, $event ) = @_;

    $self->radiobut1_1->SetValue( 1 );
}

sub OnRadioButton_Sel2 {
    my( $self, $event ) = @_;

    $self->radiobut1_2->SetValue( 1 );
}

sub add_to_tags { qw(controls) }
sub title { 'wxRadioButton' }

1;
