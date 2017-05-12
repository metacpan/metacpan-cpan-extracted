#############################################################################
## Name:        lib/Wx/DemoModules/wxRichToolTip.pm
## Purpose:     wxPerl demo helper for Wx::RichToolTip
## Author:      Mark Dootson
## Modified by:
## Created:     19/03/2012
## RCS-ID:      $Id: wxRichToolTip.pm 3229 2012-03-19 04:05:07Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxRichToolTip;

use strict;
use Wx qw( wxICON_INFORMATION );
use base qw(Wx::Panel);
use Wx::Event qw(EVT_BUTTON);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( $_[0], -1 );

    my $show = Wx::Button->new( $self, -1, 'Show tip', [20, 20] );

    EVT_BUTTON( $self, $show, \&on_show_tip );
    return $self;
}

sub on_show_tip {
    my( $self, $event ) = @_;
    my $tip = Wx::RichToolTip->new('Wx::Demo Tip', qq(You can add a tip with any text\nand newlines if you wish.\nTimeout set for 5 seconds.));
    $tip->SetIcon( wxICON_INFORMATION );
    $tip->SetTimeout( 5000 ); # milliseconds
    $tip->ShowFor( $self );   # tip will be show for this panel
    
    # $tip->SetIcon( Wx::Icon->new($icon)); 
    
}

sub add_to_tags { qw(windows new) }
sub title { 'wxRichToolTip' }

#Skip loading if no native wxTreeListCtrl
return defined(&Wx::RichToolTip::new);
