#############################################################################
## Name:        lib/Wx/DemoModules/wxTipDialog.pm
## Purpose:     wxPerl demo helper for Wx::TipDialog
## Author:      Mattia Barbon
## Modified by:
## Created:     26/08/2007
## RCS-ID:      $Id: wxTipDialog.pm 2812 2010-02-20 10:53:40Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxTipDialog;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx qw();
use Wx::Event qw(EVT_BUTTON);

__PACKAGE__->mk_accessors( qw(provider) );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( $_[0], -1 );

    my $tip_file = Wx::Demo->get_data_file( 'tipdialog/tips.txt' );
    my $provider = Wx::CreateFileTipProvider( $tip_file, 0 );

    $self->provider( $provider );

    my $show = Wx::Button->new( $self, -1, 'Show tip', [20, 20] );

    EVT_BUTTON( $self, $show, \&on_show_tip );

    return $self;
}

sub on_show_tip {
    my( $self, $event ) = @_;

    my $show_again = Wx::ShowTip( $self, $self->provider, 1 );

    Wx::LogMessage( $show_again ? 'Show tips at startup' :
                                  'Do not show tips at startup' );
    Wx::LogMessage( 'Current tip is %d', $self->provider->GetCurrentTip );
}

sub add_to_tags { qw(dialogs) }
sub title { 'wxTipDialog' }

1;
