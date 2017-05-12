#############################################################################
## Name:        lib/Wx/DemoModules/wxWizard.pm
## Purpose:     wxPerl demo helper for Wx::Wizard
## Author:      Mattia Barbon
## Modified by:
## Created:     28/08/2002
## RCS-ID:      $Id: wxWizard.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2002, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxWizard;

use strict;
use base qw(Wx::Panel);

use Wx qw(wxDefaultPosition wxDefaultSize);
use Wx::Event qw(EVT_WIZARD_PAGE_CHANGED EVT_BUTTON);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    my $button = Wx::Button->new( $self, -1, "Start wizard", [20, 20] );
    my $wizard = Wx::Wizard->new( $self, -1, "Wizard test" );

    # first page
    my $page1 = Wx::WizardPageSimple->new( $wizard );
    Wx::TextCtrl->new( $page1, -1, "First page" );

    # second page
    my $page2 = Wx::WizardPageSimple->new( $wizard );
    Wx::TextCtrl->new( $page2, -1, "Second page" );

    Wx::WizardPageSimple::Chain( $page1, $page2 );

    EVT_WIZARD_PAGE_CHANGED( $self, $wizard, sub {
                                 Wx::LogMessage( "Wizard page changed" );
                             } );

    EVT_BUTTON( $self, $button, sub {
                    $wizard->RunWizard( $page1 );
                } );

    return $self;
}

sub OnCheck {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Element %d toggled to %s", $event->GetInt(),
                    ( $self->IsChecked( $event->GetInt() ) ?
                      'checked' : 'unchecked' ) );
}

sub add_to_tags { qw(managed) }
sub title { 'wxWizard' }

1;
