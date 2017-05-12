#
# This file is part of Tk-Role-Dialog
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Tk::Role::Dialog;
{
  $Tk::Role::Dialog::VERSION = '1.112380';
}
# ABSTRACT: moose role for enhanced tk dialogs

use File::Basename             qw{ fileparse };
use Moose::Role 0.92;
use MooseX::Has::Sugar;
use MooseX::Types::Path::Class qw{ File };
use Tk;
use Tk::JPEG;
use Tk::PNG;
use Tk::Sugar;

with 'Tk::Role::HasWidgets' => { -version => 1.112380 }; # _clear_w


# -- accessors


has parent    => ( ro, required, weak_ref, isa=>'Tk::Widget' );
has hidden    => ( ro, lazy_build, isa=>'Bool' );
has icon      => ( ro, lazy_build, isa=>File, coerce );
has title     => ( ro, lazy_build, isa=>'Str' );
has header    => ( ro, lazy_build, isa=>'Str' );
has text      => ( ro, lazy_build, isa=>'Str' );
has image     => ( ro, lazy_build, isa=>'Str' );
has resizable => ( ro, lazy_build, isa=>'Bool' );
has ok        => ( ro, lazy_build, isa=>'Str' );
has cancel    => ( ro, lazy_build, isa=>'Str' );
has hide      => ( ro, lazy_build, isa=>'Str' );

has _toplevel => ( rw, lazy_build, isa=>'Tk::Toplevel' );



# -- initialization / finalization

# those are defaults for the role public attributes
sub _build_hidden    { 0 }
sub _build_title     { 'tk dialog' }
sub _build_icon      { '' }
sub _build_header    { '' }
sub _build_image     { '' }
sub _build_text      { '' }
sub _build_resizable { 0 }
sub _build_ok        { '' }
sub _build_cancel    { '' }
sub _build_hide      { '' }

sub _build__toplevel {
    my $self = shift;
    return $self->parent->Toplevel;
}


#
# BUILD()
#
# called as constructor initialization
#
sub BUILD { }
after BUILD => sub {
    my $self = shift;
    $self->_build_dialog;
};



# -- gui methods


sub close {
    my $self = shift;
    $self->_toplevel->destroy;
}


# -- private methods

#
# dialog->_build_dialog;
#
# create the various gui elements.
#
sub _build_dialog {
    my $self = shift;

    my $top = $self->_toplevel;
    $top->withdraw;

    if ( $self->icon ) {
        my $icon = $top->Photo( -file => $self->icon );
        $top->iconimage( $icon );
        # transparent images have a xbm mask
        my ($file, $path, undef) = fileparse( $self->icon, qr/\.png/i );
        my $mask = $path . "$file-mask.xbm";
        $top->iconmask( '@' . $mask ) if -f $mask;
    }

    # dialog name
    if ( $self->header ) {
        my $font = $top->Font(-size=>16);
        $top->Label(
            -text => $self->header,
            -bg   => 'black',
            -fg   => 'white',
            -font => $font,
        )->pack(top, pad10, ipad10, fill2);
    }

    # build inner gui elements
    if ( $self->text ) {
        my $f = $top->Frame->pack(top, xfill2);
        if ( $self->image ) {
            my $image = $top->Photo( -file => $self->image );
            $f->Label(-image => $image)->pack(left, fill2, pad10);
        }
        $f->Label(
            -text       => $self->text,
            -justify    => 'left',
            -wraplength => '8c',
        )->pack(left, fill2, pad10);
    }
    if ( $self->can( '_build_gui' ) ) {
        my $f = $top->Frame->pack(top,xfill2);
        $self->_build_gui($f);
    }

    # the dialog buttons.
    # note that we specify a bogus width in order for both buttons to be
    # the same width. since we pack them with expand set to true, their
    # width will grow - but equally. otherwise, their size would be
    # proportional to their english text.
    my $fbuttons = $top->Frame->pack(top, fillx);
    if ( $self->ok ) {
        my $but = $fbuttons->Button(
            -text    => $self->ok,
            -width   => 10,
            -command => sub { $self->_valid },
        )->pack(left, xfill2);
        $self->_set_w('ok', $but);
        $top->bind('<Return>', sub { $self->_valid });
        $top->bind('<Escape>', sub { $self->_valid }) unless $self->cancel;
    }
    if ( $self->hide ) {
        my $but = $fbuttons->Button(
            -text    => $self->hide,
            -width   => 10,
            -command => sub { $top->withdraw },
        )->pack(left, xfill2);
        $self->_set_w('hide', $but);
        $top->bind('<Return>', sub { $top->withdraw }) unless $self->ok;
        $top->bind('<Escape>', sub { $top->withdraw }) unless $self->cancel;
    }
    if ( $self->cancel ) {
        my $but = $fbuttons->Button(
            -text    => $self->cancel,
            -width   => 10,
            -command => sub { $self->close },
        )->pack(left, xfill2);
        $self->_set_w('cancel', $but);
        $top->bind('<Escape>', sub { $self->close });
        $top->bind('<Return>', sub { $self->close }) unless $self->ok;
    }

    # window title
    # this should come at the end, since some widgets (i'm looking at
    # you tk::pod::text!) change the window title - tsk!
    $top->title( $self->title );

    # center window & make it appear
    $top->Popup( -popover => $self->parent ) unless $self->hidden;
    if ( $self->resizable ) {
        $top->minsize($top->width, $top->height);
    } else {
        $top->resizable(0,0);
    }

    # allow dialogs to finish once everything is in place
    $self->_finish_gui if $self->can('_finish_gui');
}

no Moose::Role;
1;


=pod

=head1 NAME

Tk::Role::Dialog - moose role for enhanced tk dialogs

=head1 VERSION

version 1.112380

=head1 SYNOPSIS

    package Your::Tk::Dialog::Class;

    use Moose;
    with 'Tk::Role::Dialog';

    sub _build_title     { 'window title' }
    sub _build_icon      { '/path/to/some/icon.png' }
    sub _build_header    { 'big dialog header' }
    sub _build_resizable { 0 }
    sub _build_ok        { 'frobnize' }     # call $self->_valid
    sub _build_cancel    { 'close' }        # close the window

    sub _build_gui {
        my ($self, $frame) = @_;
        # build the inner dialog widgets in the $frame
    }
    sub _valid {
        # called when user clicked the 'ok' button
        $self->close;
    }


    # in your main program
    use Your::Tk::Dialog::Class;
    # create & show a new dialog
    Your::Tk::Dialog::Class->new( parent => $main_window );

=head1 DESCRIPTION

L<Tk::Role::Dialog> is meant to be used as a L<Moose> role to be
composed for easy L<Tk> dialogs creation.

It will create a new toplevel with a title, and possibly a header as
well as some buttons.

One can create the middle part of the dialog by providing a
C<_build_gui()> method, that will receive a L<Tk::Frame> where widgets
are supposed to be placed.

The attributes (see below) can be either defined as defaults using the
C<_build_attr()> methods, or passed arguments to the constructor call.
The only mandatory attribute is C<parent>, but you'd better provide some
other attributes if you want your dialog to be somehow usable! :-)

=head1 ATTRIBUTES

=head2 parent

The parent window of the dialog, required.

=head2 hidden

Whether the dialog should popup or stay hidden after creation. Default
to false, which means the dialog is shown.

=head2 icon

The path to an image to be used as window icon. Default to empty string
(meaning no customized window icon), but not required.

=head2 title

The dialog title, default to C<tk dialog>.

=head2 header

A header (string) to display at the top of the window. Default to empty
string, meaning no header.

=head2 image

The path to an image to be displayed alongside the dialog text. Not
taken into account if C<text> attribute is empty. Default to empty
string, meaning no image.

=head2 text

Some text to be displayed, for simple information dialog boxes. Default
to empty string, meaning dialog is to be filled by providing a
C<_build_gui()> method. Can be combined with an C<image> attribute for
enhanced appearance.

=head2 resizable

A boolean to control whether the dialog can be resized or not (default).

=head2 ok

A string to display as validation button label. Default to empty string,
meaning no validation button. The validation action will call
C<< $self->_valid() >>.

=head2 cancel

A string to display as cancellation button label. Default to empty
string, meaning no cancellation button. The cancel action is to just
close the dialog.

=head2 hide

A string to display as hiding button label. Default to empty
string, meaning no hiding button. The hiding action is to just
hide the dialog (think C<withdraw>).

=head1 METHODS

=head2 close

    $dialog->close;

Request to destroy the dialog.

=for Pod::Coverage BUILD
    DEMOLISH

=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Role-Dialog>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Role-Dialog>

=item * Git repository

L<http://github.com/jquelin/tk-role-dialog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Role-Dialog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Role-Dialog>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

