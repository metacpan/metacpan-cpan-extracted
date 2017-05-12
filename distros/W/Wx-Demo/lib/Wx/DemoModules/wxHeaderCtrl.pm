#############################################################################
## Name:        lib/Wx/DemoModules/wxHeaderCtrl.pm
## Purpose:     wxPerl demo helper for Wx::HeaderCtrl/Wx::HeaderColumn
## Author:      Mattia Barbon
## Modified by:
## Created:     25/04/2010
## RCS-ID:      $Id: wxHeaderCtrl.pm 2920 2010-04-29 21:11:27Z mbarbon $
## Copyright:   (c) 2010 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxHeaderCtrl;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(headerctrl) );

sub create_control {
    my( $self ) = @_;

    my $headerctrl = Wx::DemoModules::wxHeaderCtrl::Control->new( $self );
    $headerctrl->SetColumnCount( 3 );

    return $self->headerctrl( $headerctrl );
}

sub add_to_tags { ( Wx::wxVERSION() >= 2.009 ) ? qw(controls new) : () }
sub title { 'wxHeaderCtrl' }

package Wx::DemoModules::wxHeaderCtrl::Control;

use strict;
use base qw(Wx::PlHeaderCtrl);

sub GetColumn {
    my( $self, $index ) = @_;

    return $self->{columns}[$index] if $self->{columns}[$index];

    my $col = $self->{columns}[$index] =
        Wx::DemoModules::wxHeaderCtrl::Column->new;
    $col->{index} = $index + 1;

    return $self->{columns}[$index];
}

package Wx::DemoModules::wxHeaderCtrl::Column;

use strict;
use base qw(Wx::PlHeaderColumn);

use Wx qw(wxALIGN_CENTER);

sub GetTitle {
    my( $self ) = @_;

    return 'Column ' . $self->{index};
}

sub GetWidth {
    my( $self ) = @_;

    return $self->{index} * 100;
}

sub GetAlignment {
    my( $self ) = @_;

    return wxALIGN_CENTER;
}

1;
