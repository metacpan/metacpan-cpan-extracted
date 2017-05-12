#
# This file is part of Tk-ObjEditor
#
# This software is copyright (c) 2014 by Dominique Dumont.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Tk::ObjEditorDialog;
$Tk::ObjEditorDialog::VERSION = '2.009';
use strict;
use warnings;

use Carp;
use Tk::ObjEditor;

use vars qw/$VERSION @ISA/;

#use Storable qw(dclone);

use base qw(Tk::Derived Tk::DialogBox);

Tk::Widget->Construct('ObjEditorDialog');

sub Populate {
    my ( $cw, $args ) = @_;

    my $data = delete $args->{'caller'} || delete $args->{'-caller'};
    $cw->{direct} = delete $args->{'direct'} || delete $args->{'-direct'} || 0;

    # need to add different button for clone ????
    my $buttons = $cw->{direct} ? ['done'] : [qw/OK cancel/];

    $args->{-buttons} = $buttons;

    $cw->SUPER::Populate($args);

    $cw->add( 'ObjEditor', caller => $data, -direct => $cw->{direct} )->pack;

    return $cw;
}

sub Show {
    my $cw = shift;

    my $hit = $cw->SUPER::Show(@_);

    if ( $hit eq 'OK' ) {

        # no direct edit
        return $cw->Subwidget("objeditor")->get_data();
    }
    else {
        return $cw->Subwidget("objeditor")->get_orig_data();
    }
}

=head1 NAME

Tk::ObjEditorDialog - Tk composite widget obj editor popup dialog

=head1 SYNOPSIS

  use Tk::ObjEditorDialog;
  
  my $editor = $mw->ObjEditorDialog( caller => $object, 
                                      direct => [1|0],
                                      [title=>"windows"]) ;

  $editor -> Show;

=head1 DESCRIPTION

This widget is a L<ObjEditor> within a L<DialogBox> widget. I.e. it
will appear in its own toplevel window when you invoke the Show()
method like the FileDialog widget.

=head1 Constructor parameters

=over 4

=item *

caller: The ref of the object or hash or array to edit (mandatory).

=item *

title: the title of the menu created by the editor (optional)

=item *

direct: Set to 1 if you want to perform direct edition.

=back

=head1 Method

=head2 Show(grab)

As in L<Tk::DialogBox>, this method displays the dialog box, until
user invokes one of the buttons in the bottom frame. If the grab type
is specified in grab, then Show uses that grab; otherwise it uses a
local grab. Returns the name of the button invoked.

=head1 CAVEATS

Like L<Tk::ObjScanner> ObjEditor does not detect recursive data
structures. It will just keep on displaying the tree until the user
gets tired of clicking on the HList items.

=head1 AUTHOR

Dominique Dumont.

Copyright (c) 2001 Dominique Dumont. All
rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<Tk>, L<Tk::HList>, L<Tk::ObjScanner>, L<Tk::ObjEditor>,
L<Tk::DialogBox>

=cut

