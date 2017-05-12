#
# This file is part of Tk-ObjEditor
#
# This software is copyright (c) 2014 by Dominique Dumont.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Tk::ObjEditor;
$Tk::ObjEditor::VERSION = '2.009';
use Carp;
use Tk::Derived;
use Tk::Frame;
use Tk::ObjScanner 2.010;
use Tk::Dialog;
use Tk::DialogBox;
use warnings;
use strict;
use 5.10.1;
use Scalar::Util 1.01 qw(reftype);

use vars qw/$VERSION @ISA/;

use Storable qw(dclone);

use base qw(Tk::Derived Tk::ObjScanner);

Tk::Widget->Construct('ObjEditor');

sub _isa {
    return (reftype($_[0]) // '') eq $_[1] ;
}

sub edit_object {
    require Tk;
    import Tk;
    my $object = shift;

    my $mw = MainWindow->new;
    $mw->geometry('+10+10');
    my $s = $mw->ObjEditor(
        '-caller' => $object,
        -direct   => 1,
        -title    => 'object editor'
    );

    $s->pack( -expand => 1, -fill => 'both' );
    $s->OnDestroy( sub { $mw->destroy; } );

    &MainLoop;    # Tk's
}

sub InitObject {
    my ( $cw, $args ) = @_;

    my $data = delete $args->{'caller'} || delete $args->{'-caller'};
    $cw->{direct} =
        delete $args->{'direct'} || delete $args->{'-direct'} || 0;

    $cw->{user_data} = $data;

    my $edited_data = $cw->{direct} ? $data : dclone($data);

    $args->{'-caller'}    = $edited_data;    # to pass to ObjScanner
    $args->{'-show_tied'} = 0;               # do not show tied data internal

    $args->{title} = ref($data) . ' editor'
        unless ( defined $args->{title} || defined $args->{-title} );

    $cw->SUPER::InitObject($args);

    $cw->Subwidget('hlist')->bind( '<B3-ButtonRelease>', sub { $cw->modify_menu() } );

    $cw->{actions} = [];

    return $cw;
}

sub modify_menu {
    my $cw   = shift;
    my $item = shift;    # reserved for tests

    unless ( defined $item ) {

        # pointery and rooty are common widget method and must called on
        # the right widget to give accurate results
        my $hlist = $cw->Subwidget('hlist');
        $item = $cw->nearest( $hlist->pointery - $hlist->rooty );
    }

    $cw->selectionClear();    # clear all
    $cw->selectionSet($item);

    #print "item $item to modify\n";

    my $menu = $cw->Menu;

    my $ref = $cw->info( "data", $item )->{item_ref};
    my @children = $cw->infoChildren($item);

    if ( not $cw->isPseudoHash($$ref)
        and ( _isa( $$ref, 'ARRAY' ) or _isa( $$ref, 'HASH' ) ) ) {
        $menu->add(
            'command',
            '-label'   => 'add element',
            '-command' => sub { $cw->add_entry($item); } );
    }
    elsif ( not ref($$ref) ) {
        $menu->add(
            'command',
            '-label'   => 'modify element',
            '-command' => sub { $cw->modify_entry($item); } );
    }

    if ( $item eq 'root' ) {
        $menu->add(
            'command',
            '-label'   => 'reset',
            '-command' => sub { $cw->reset; } ) unless $cw->{direct};
    }
    else {
        $menu->add(
            'command',
            '-label'   => 'delete',
            '-command' => sub { $cw->delete_entry($item); } );
    }

    $menu->Popup( -popover => 'cursor', -popanchor => 'nw' );

    return $menu;
}

sub reset {
    my $cw = shift;

    $cw->{chief} = dclone( $cw->{user_data} );
    $cw->updateListBox();
}

# returns the edited data (a clone in case of no-direct option)
sub get_data {
    my $cw = shift;

    return $cw->{chief};
}

sub get_orig_data {
    my $cw = shift;

    return $cw->{user_data};
}

sub modify_entry {
    my $cw      = shift;
    my $item    = shift;
    my $is_text = shift || 0;

    my $text = $cw->entrycget( $item, '-text' );
    my ($item_key) = ( $text =~ m/^[\[\{](.*?)[\]\}]->/ );

    my $c_data = $cw->entrycget( $item, '-data' );
    my $ref = $c_data->{item_ref};

    my $modified = $cw->modify_widget( $ref, $is_text );

    return unless $modified;

    # replace value in parent sdata structure
    $cw->update_item($item);

}

sub update_item {
    my ( $cw, $item ) = @_[ 0, 1 ];
    my $direction = $_[2] || '';

    my $c_data = $cw->entrycget( $item, '-data' );
    my $parent_item = $cw->info( "parent", $item );
    my $parent_c_data = $cw->entrycget( $parent_item, '-data' );
    my $parent_ref =
          $item eq 'root'                ? $cw->{chief}
        : $parent_c_data->{tied_display} ? \tied( ${ $parent_c_data->{item_ref} } )
        :                                  $parent_c_data->{item_ref};

    # update HList display
    my $text = $cw->describe_element( $parent_ref, $c_data->{index} );
    $cw->entryconfigure( $item, -text => $text );

    # update parent if necessary
    if ( $parent_c_data->{tied_display} and $direction ne 'down' ) {
        $cw->update_item( $parent_item, 'up' );
    }

    # update below if necessary
    if ( $c_data->{tied_display} and $direction ne 'up' ) {
        my $h = $cw->Subwidget('hlist');
        foreach my $child ( $h->infoChildren($item) ) {
            $cw->update_item( $child, 'down' );
        }
    }
}

sub modify_widget {
    my $cw      = shift;
    my $ref     = shift;
    my $is_text = shift;

    # construct popup dialog to change item value.
    my $db = $cw->DialogBox(
        -title   => 'modify element',
        -buttons => [ "OK", "Cancel" ] );
    $cw->{current_dialog} = $db;

    # Note: focus is taken over by DialogBox and given to "OK"

    $db->add( 'Label', -text => 'Please enter new value' )->pack;

    my $textw;
    if ( $is_text or ( defined $$ref and $$ref =~ /\n/ ) ) {
        $textw = $db->add('Text')->pack( -expand => 1, -fill => 'both' );
        $textw->insert( 'end', $$ref );
        $db->bind( '<Return>', '' );    # remove Dialog Box binding on return
        $db->Advertise( 'Entry' => $textw );
    }
    else {
        my $entry = $db->add( 'Entry', -textvariable => $ref )->pack( -expand => 1, -fill => 'x' );
        $db->Advertise( 'Entry' => $entry );
    }

    # Show method should be enhanced to accept a "focus" parameter
    # so focus could be given to the actual editing widget
    my $answer = $db->Show;

    return 0 unless $answer eq "OK";

    # the '- 1c' skips the newline erroneously added by the text widget
    # Thanks Slaven
    $$ref = $textw->get( '1.0', 'end - 1c' ) if defined $textw;
    return 1;
}

sub add_entry {
    my $cw   = shift;
    my $item = shift;

    # construct popup dialog to change item value.
    my $db = $cw->DialogBox(
        -title   => 'add element',
        -buttons => [ "OK", "Cancel" ] );

    my $ok = $db->Subwidget('B_OK');

    # enforce that a type is choosen by the user and that a new key is used
    my ( $key_ok, $type_ok ) = ( 0, 0 );
    my $check = sub {
        my $what = $key_ok && $type_ok ? 'normal' : 'disabled';
        $ok->configure( -state => $what );
    };

    &$check;    # for fun and for test

    my $ref_ref = $cw->entrycget( $item, '-data' )->{item_ref};
    my $ref = $$ref_ref;

    my $is_hash_like = _isa( $ref, 'HASH' );

    my $what = $is_hash_like ? 'key' : 'index';
    $db->add( 'Label', -text => "enter new $what" )->pack;

    my $key = $is_hash_like ? '' : scalar(@$ref);

    $db->add(
        'Entry',
        -textvariable    => \$key,
        -validate        => 'key',
        -validatecommand => sub {
            my $prop = shift;

            #print "key: '$prop'\n";
            if (   ( $is_hash_like and not exists $ref->{$prop} )
                or ( _isa( $ref, 'ARRAY' ) and not defined $ref->[$prop] ) ) {
                $key_ok = 1;
            }
            else { $key_ok = 0; }
            &$check;
            1;
        } )->pack;

    $db->add( 'Label', -text => "Specify new element type" )->pack;
    my $type = 'undef';
    my $mb   = $db->add(
        'Menubutton',
        -textvariable => \$type,
        qw/-indicatoron 1 -relief raised/
    );

    my $menu = $mb->Menu( -tearoff => 0 );
    $mb->configure( -menu => $menu );

    foreach (qw/array hash scalar text/) {
        $mb->radiobutton(
            -label       => $_,
            -value       => $_,
            -variable    => \$type,
            -indicatoron => 0,
            -command     => sub { $type_ok = 1; &$check; } );
    }

    $mb->pack;
    return if $db->Show ne 'OK';

    # update data structure
    my $new;
    if    ( $type eq 'hash' )  { $new = {}; }
    elsif ( $type eq 'array' ) { $new = []; }
    elsif ( $type eq 'text' ) { $cw->modify_widget( \$new, 1 ); }
    else                      { $cw->modify_widget( \$new, 0 ); }

    return unless defined $new;

    $ref->{$key} = $new if _isa( $ref, 'HASH' );
    $ref->[$key] = $new if _isa( $ref, 'ARRAY' );

    #recompute the text for parent widget
    my $text = $cw->element( \$ref );
    $cw->entryconfigure( $item, '-text', $text );

    #(re)display the children
    $cw->deleteOffsprings($item);
    $cw->displaySubItem($item);    # by default do not display tied internals
}

sub delete_entry {
    my $cw   = shift;
    my $item = shift;

    my $item_key = $cw->entrycget( $item, '-data' )->{index} || '';

    my $dialog = $cw->Dialog(
        -title   => 'WARNING',
        -text    => "Delete the '$item_key' element and all its children ?",
        -buttons => [ "Yes", "No" ] );
    my $answer = $dialog->Show();

    return if $answer eq "No";

    my $parent_item = $cw->info( "parent", $item );
    my $text_parent = $cw->entrycget( $parent_item, "-text" );
    my $parent_ref  = $cw->entrycget( $parent_item, '-data' )->{item_ref};

    delete $$parent_ref->{$item_key} if _isa( $$parent_ref, 'HASH' );
    splice @$$parent_ref, $item_key, 1 if _isa( $$parent_ref, 'ARRAY' );

    $cw->entryconfigure( $parent_item, "-text", $cw->element($parent_ref) );

    $cw->deleteEntry($item);
}

# used for tests
sub get_current_dialog {
    my $self = shift;
    return $self->{current_dialog};
}

1;

__END__

=head1 NAME

Tk::ObjEditor - Tk composite widget Obj editor

=head1 SYNOPSIS

  use Tk::ObjEditor;
  
  my $editor = $mw->ObjEditor( caller => $object, 
                                direct => [1|0],
                                [title=>"windows"]) -> pack ;

=head1 DESCRIPTION

This widget provides a GUI to edit the attributes of an object or the
elements of a simple hash or array.

The editor is a L<Tk::ObjScanner> with additional function to edit
data.  The editor can be used in an autonomous way with the
C<edit_object> function.

When the user double clicks (with left button) on an item, the
value of the item will be displayed in the HList.

If the value is a scalar, the scalar will be displayed in the text window.
(Which is handy if the value is a multi-line string)

If you use the middle button and the item (either hash, array or
scalar) is tied to an object , you will open the object hidden behind
the tied variable.

Use the right button of the mouse of an element to modify its
value. Depending on the context, you will also be able to delete the
element or to add a sub-element.

This may be not clear. If yes, I think that trying this widget will be
much clearer than any explanation I can write. So run the Tk widget
demo and you'll find the Obj editor demo in the "User Contributed
Demonstration" section.

=head1 Direct or undirect edit

As the constructor will pass a reference to the data structure to be
edited, the data can be edited :

=over

=item not directly

In this case, the data structure is cloned. The widget will edit the
cloned version of the data structure. This enable the user to cancel
the edition. This means that any reference to the internals of old
data structure will stay on the old datastructure and will not be
aware of the new values entered with this widget.

Unforunately, undirect edition will break if the cloned data structure
contains code reference.

=item directly

In this case, the data structure is not cloned. The edition is
performed on the passed reference. Any reference to the internals of
old data structure will be updated on-line. The drawback is that the
user cannot cancel (or undo) the edition.

=back

=head1 Constructor parameters

=over 4

=item *

-caller: The ref of the object or hash or array to edit (mandatory).

=item *

-title: the title of the menu created by the editor (optional)

=item *

-direct: Set to 1 if you want to perform direct edition.

=back

=head1 Autonomous widget

=head2 edit_object( data )

This function is not exported and must be called this way:

  Tk::ObjEditor::edit_object($data);

This function will load Tk and pop up an editor widget. When the user
destroy the widget (with C<File -> destroy> menu), the user code is
resumed.

=head1 CAVEATS

Like L<Tk::ObjScanner> ObjEditor does not detect recursive data
structures. It will just keep on displaying the tree until the user
gets tired of clicking on the HList items.

ObjEditor cannot edit code reference. The module will break if you
try undirect edition of data containing code references.

=head1 AUTHOR

Dominique Dumont (ddumont at cpan.org), Guillaume Degremont.

=head1 LICENSE

Copyright (c) 1997-2004,2007,2014 Dominique Dumont, Guillaume Degremont. All
rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<Tk>, L<Tk::HList>, L<Tk::ObjScanner>

=cut


