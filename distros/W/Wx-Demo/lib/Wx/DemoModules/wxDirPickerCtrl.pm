#############################################################################
## Name:        lib/Wx/DemoModules/wxDirPickerCtrl.pm
## Purpose:     wxPerl demo helper for Wx::DirPickerCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     01/11/2006
## RCS-ID:      $Id: wxDirPickerCtrl.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxDirPickerCtrl;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx::Event qw(EVT_DIRPICKER_CHANGED);

__PACKAGE__->mk_accessors( qw(picker) );

=pod

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Set italic font',
               action      => sub { $self->picker->SetDir( wxITALIC_FONT ) },
               },
               );
}

=cut

sub create_control {
    my( $self ) = @_;

    my $dp = Wx::DirPickerCtrl->new( $self, -1, "", "Choose a directory",
                                     [-1, -1], [-1, -1], $self->style );
    EVT_DIRPICKER_CHANGED( $self, $dp, \&on_change );

    return $self->picker( $dp );
}

sub on_change {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Directory changed (%s)", $event->GetPath );
}

sub tags { [ 'controls/picker' => 'Picker controls' ] }
sub add_to_tags { qw(controls/picker) }
sub title { 'wxDirPickerCtrl' }

defined &Wx::DirPickerCtrl::new ? 1 : 0;
