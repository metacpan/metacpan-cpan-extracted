#############################################################################
## Name:        lib/Wx/DemoModules/wxSimpleHtmlListBox.pm
## Purpose:     wxPerl demo helper for Wx::SimpleHtmlListBox
## Author:      Mattia Barbon
## Modified by:
## Created:     01/11/2006
## RCS-ID:      $Id: wxSimpleHtmlListBox.pm 3043 2011-03-21 17:25:36Z mdootson $
## Copyright:   (c) 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Html;

package Wx::DemoModules::wxSimpleHtmlListBox;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:htmllistbox wxNOT_FOUND);
use Wx::Event qw(EVT_LISTBOX EVT_LISTBOX_DCLICK);

__PACKAGE__->mk_accessors( qw(listbox) );

sub expandinsizer { 1 };

sub styles {
    my( $self ) = @_;

    return ( [ wxHLB_MULTIPLE, 'Multiple selection' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Select item',
               with_value  => 1,
               action      => sub { $self->listbox->SetSelection( $_[0] ) },
               },
             { label       => 'Clear',
               action      => sub { $self->listbox->Clear },
               },
             { label       => 'Append',
               with_value  => 1,
               action      => sub { $self->listbox->Append( $_[0] ) },
               },
             { label       => 'Delete selected item',
               action      => \&on_delete_selected,
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $choices = [ map { "<h$_>Test!</h$_>" } ( 1 .. 6 ) ];
    my $listbox = Wx::SimpleHtmlListBox->new( $self, -1, [-1, -1],
                                              [400, 400], $choices,
                                              $self->style );

    EVT_LISTBOX( $self, $listbox, \&OnListBox );
    EVT_LISTBOX_DCLICK( $self, $listbox, \&OnListBoxDoubleClick );

    return $self->listbox( $listbox );
}

sub OnListBox {
    my( $self, $event ) = @_;

    if( $event->GetInt() == -1 ) {
        Wx::LogMessage( "ListBox has no selections any more" );
        return;
    }

    Wx::LogMessage( "ListBox selection string is '%s'",
                    $self->listbox->GetString( $event->GetInt ) );
}

sub OnListBoxDoubleClick {
    my( $self, $event ) = @_;

    my $idx = $self->listbox->GetSelection;
    Wx::LogMessage( "ListBox double click string is '%s'",
                    $self->listbox->GetString( $event->GetInt ) );
}

sub on_delete_selected {
    my( $self ) = @_;
    my( $idx );

    if( ( $idx = $self->listbox->GetSelection() ) != wxNOT_FOUND ) {
        $self->listbox->Delete( $idx );
    }
}

sub add_to_tags { qw(controls) }
sub title { 'wxSimpleHtmlListBox' }

defined &Wx::SimpleHtmlListBox::new ? 1 : 0;
