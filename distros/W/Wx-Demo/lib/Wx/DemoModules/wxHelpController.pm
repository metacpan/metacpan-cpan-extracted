#############################################################################
## Name:        lib/Wx/DemoModules/wxHelpController.pm
## Purpose:     wxPerl demo helper
## Author:      Mattia Barbon
## Modified by:
## Created:     27/03/2007
## RCS-ID:      $Id: wxHelpController.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Html;
use Wx::Help;
use Wx::FS;

package Wx::DemoModules::wxHelpController;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(html_help chm_help) );

use Wx qw(wxHF_FLATTOOLBAR wxHF_DEFAULTSTYLE);
use Wx::Event qw(EVT_BUTTON);

# very important for HTB to work
Wx::FileSystem::AddHandler( new Wx::ZipFSHandler );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( $_[0], -1 );

    $self->{html_help} = Wx::HtmlHelpController->new
                             ( wxHF_FLATTOOLBAR|wxHF_DEFAULTSTYLE );
    EVT_BUTTON( $self, Wx::Button->new( $self, -1, 'Show Html Help',
                                        [10, 10] ),
                \&show_html_help );
    if( Wx::CHMHelpController->can( 'new' ) ) {
        $self->{chm_help} = Wx::CHMHelpController->new;
        EVT_BUTTON( $self, Wx::Button->new( $self, -1, 'Show CHM Help',
                                            [10, 60] ),
                    \&show_chm_help );
    }

    return $self;
}

sub tags { [ 'misc/help' => 'Help' ] }
sub add_to_tags { qw(misc/help) }
sub title { 'wxHelpController' }

sub show_html_help {
    my( $self ) = @_;

    my $htb_file = Wx::Demo->get_data_file( 'help/example.htb' );

    $self->html_help->AddBook( $htb_file, 1 );
    $self->html_help->DisplayContents;
}

sub show_chm_help {
    my( $self ) = @_;

    my $chm_file = Wx::Demo->get_data_file( 'help/example.chm' );

    $self->chm_help->Initialize( $chm_file );
    $self->chm_help->DisplayContents;
}

1;
