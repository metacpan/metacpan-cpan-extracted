#############################################################################
## Name:        lib/Wx/DemoModules/wxHtmlListBox.pm
## Purpose:     wxPerl demo helper for Wx::HtmlListBox
## Author:      Mattia Barbon
## Modified by:
## Created:     21/09/2006
## RCS-ID:      $Id: wxHtmlListBox.pm 3043 2011-03-21 17:25:36Z mdootson $
## Copyright:   (c) 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Html;

package Wx::DemoModules::wxHtmlListBox;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(wxLB_MULTIPLE);
use Wx::Event qw(EVT_LISTBOX EVT_LISTBOX_DCLICK);

__PACKAGE__->mk_accessors( qw(htmllistbox) );

sub expandinsizer { 1 };

sub styles {
    my( $self ) = @_;

    return ( [ wxLB_MULTIPLE, 'Multiple selection' ],
             );
}

sub create_control {
    my( $self ) = @_;

    my $listbox = Wx::DemoModules::wxHtmlListBox::Custom->new
        ( $self, -1, [-1, -1], [400, 400], $self->style );

    EVT_LISTBOX( $self, $listbox, \&OnHtmlListBox );
    EVT_LISTBOX_DCLICK( $self, $listbox, \&OnHtmlListBoxDoubleClick );

    return $self->htmllistbox( $listbox );
}

sub OnHtmlListBox {
    my( $self, $event ) = @_;

    if( $event->GetInt == -1 ) {
        Wx::LogMessage( "List box has no selections any more" );
        return;
    }

    Wx::LogMessage( "ListBox click item is '%d'", $event->GetInt ) ;
}

sub OnHtmlListBoxDoubleClick {
    my( $self, $event ) = @_;

    Wx::LogMessage( "ListBox double click item is '%d'", $event->GetInt ) ;
}

sub add_to_tags { qw(controls) }
sub title { 'wxHtmlListBox' }

package Wx::DemoModules::wxHtmlListBox::Custom;

use strict;
use base qw(Wx::PlHtmlListBox);

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    $self->SetItemCount( 150 );

    return $self;
}

sub OnGetItem {
    my( $self, $item ) = @_;

    return sprintf <<EOT, $item, join ' ', ( 'text' ) x ( $item / 3 );
<h1>%s</h1>
%s text text text text text
EOT
}

1;
