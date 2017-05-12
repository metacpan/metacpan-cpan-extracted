#############################################################################
## Name:        lib/Wx/DemoModules/wxStaticBitmap.pm
## Purpose:     wxPerl demo helper for Wx::StaticBitmap
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxStaticBitmap.pm 3118 2011-11-18 09:58:12Z mdootson $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxStaticBitmap;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:icon wxTheApp wxNullBitmap);

__PACKAGE__->mk_accessors( qw(staticbitmap) );

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Clear bitmap',
               action      => \&on_clear_bitmap,
               },
             { label       => 'Set bitmap',
               action      => \&on_set_bitmap,
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $icon = wxTheApp->GetStdIcon( wxICON_INFORMATION );
    my $staticbitmap = Wx::StaticBitmap->new( $self, -1, $icon );

    return $self->staticbitmap( $staticbitmap );
}

sub on_clear_bitmap {
    my( $self ) = @_;

    $self->staticbitmap->SetBitmap( wxNullBitmap );
    $self->staticbitmap->Refresh;
}

sub on_set_bitmap {
    my( $self ) = @_;
    $self->staticbitmap->SetBitmap(Wx::Bitmap->new( wxTheApp->GetStdIcon( rand > .5 ? wxICON_QUESTION : wxICON_INFORMATION ) ) );
    $self->staticbitmap->Refresh;
}

sub add_to_tags { qw(controls) }
sub title { 'wxStaticBitmap' }

1;
