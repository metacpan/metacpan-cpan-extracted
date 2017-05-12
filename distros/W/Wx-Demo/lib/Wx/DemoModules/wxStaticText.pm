#############################################################################
## Name:        lib/Wx/DemoModules/wxStaticText.pm
## Purpose:     wxPerl demo helper for Wx::StaticText
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxStaticText.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxStaticText;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:statictext);

__PACKAGE__->mk_accessors( qw(statictext) );

sub styles {
    my( $self ) = @_;

    return ( [ wxALIGN_LEFT, 'Align left' ],
             [ wxALIGN_CENTER, 'Align center' ],
             [ wxALIGN_RIGHT, 'Align right' ],
             [ wxST_NO_AUTORESIZE, 'No autoresize' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { with_value  => 1,
               label       => 'Set label',
               action      => sub { $self->statictext->SetLabel( $_[0] ) },
               },
             );
}

sub create_control {
    my( $self ) = @_;

    my $statictext = Wx::StaticText->new( $self, -1, 'A label',
                                          [-1, -1], [100, 200],
                                          $self->style );

    return $self->statictext( $statictext );
}

sub add_to_tags { qw(controls) }
sub title { 'wxStaticText' }

1;
