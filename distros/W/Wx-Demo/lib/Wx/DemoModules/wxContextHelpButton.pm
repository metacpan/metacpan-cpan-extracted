#############################################################################
## Name:        lib/Wx/DemoModules/wxContextHelpButton.pm
## Purpose:     wxPerl demo helper
## Author:      Mattia Barbon
## Modified by:
## Created:     28/03/2007
## RCS-ID:      $Id: wxContextHelpButton.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Help;

package Wx::DemoModules::wxContextHelpButton;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx qw(wxID_CONTEXT_HELP);

__PACKAGE__->mk_ro_accessors( qw(help_button) );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( $_[0], -1 );

    # setup simple help provider
    my $provider = Wx::SimpleHelpProvider->new;
    Wx::HelpProvider::Set( $provider );

    $self->{help_button} =
      Wx::ContextHelpButton->new( $self, wxID_CONTEXT_HELP, [20, 80] );

    my $helpful = Wx::Button->new( $self, -1, 'Helpful button', [20, 20] );
    $helpful->SetHelpText( 'Help text...' );

    return $self;
}

sub tags { [ 'misc/help' => 'Help' ] }
sub add_to_tags { qw(misc/help) }
sub title { 'wxContextHelpButton' }

1;
