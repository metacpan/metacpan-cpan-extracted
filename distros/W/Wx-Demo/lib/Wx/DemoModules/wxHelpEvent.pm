#############################################################################
## Name:        lib/Wx/DemoModules/wxHelpEvent.pm
## Purpose:     wxPerl demo helper
## Author:      Mattia Barbon
## Modified by:
## Created:     28/03/2007
## RCS-ID:      $Id: wxHelpEvent.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Html;
use Wx::Help;
use Wx::FS;

package Wx::DemoModules::wxHelpEvent;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx qw(wxID_CONTEXT_HELP wxHF_FLATTOOLBAR wxHF_DEFAULTSTYLE);
use Wx::Event qw(EVT_HELP);

__PACKAGE__->mk_ro_accessors( qw(help_button help_controller) );

# very important for HTB to work
Wx::FileSystem::AddHandler( new Wx::ZipFSHandler );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( $_[0], -1 );

    # setup help controller
    if( Wx::CHMHelpController->can( 'new' ) ) {
        my $chm_file = Wx::Demo->get_data_file( 'help/example.chm' );
        $self->{help_controller} = Wx::CHMHelpController->new;
        $self->help_controller->Initialize( $chm_file );
    } else {
        my $htb_file = Wx::Demo->get_data_file( 'help/example.htb' );
        $self->{help_controller} = Wx::HtmlHelpController->new
                                       ( wxHF_FLATTOOLBAR|wxHF_DEFAULTSTYLE );
        $self->help_controller->AddBook( $htb_file, 1 );
    }

    EVT_HELP( $self, -1, sub {
                  my $win = $_[1]->GetEventObject;

                  $self->help_controller->DisplaySectionId( $win->GetName );
              } );

    $self->{help_button} =
      Wx::ContextHelpButton->new( $self, wxID_CONTEXT_HELP, [200, 20] );

    my $petrarca = Wx::Button->new( $self, -1, 'Help on Petrarca',
                                    [20, 20] );
    my $tolkien = Wx::Button->new( $self, -1, 'Help on Tolkien',
                                   [20, 80] );
    my $verlaine = Wx::Button->new( $self, -1, 'Help on Verlaine',
                                    [20, 130] );
    my $orazio = Wx::Button->new( $self, -1, 'Help on Orazio',
                                  [20, 180] );

    $petrarca->SetName( 100 );
    $tolkien->SetName( 200 );
    $verlaine->SetName( 250 );
    $orazio->SetName( 300 );

    return $self;
}

sub tags { [ 'misc/help' => 'Help' ] }
sub add_to_tags { qw(misc/help) }
sub title { 'wxHelpEvent' }

1;
