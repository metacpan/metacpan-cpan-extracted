package Tk::FileEntry;

use 5.008008;
use strict;
use warnings;
use Tk;
use Tk::widgets qw/ Frame Derived Widget Label Entry Button /;
use base qw/ Tk::Derived Tk::Frame /;

our $VERSION = '2.3';

Construct Tk::Widget 'FileEntry';

my $FILEBITMAP = undef;

=head1 NAME

Tk::FileEntry - FileEntry widget with optional file selection box

=head1 SYNOPSIS

    use Tk::FileEntry;

    $fileentry = $parent->FileEntry(
				-filebitmap	=> BITMAP,
				-command	=> CALLBACK,
				-variable	=> SCALARREF,
				);

=head1 DESCRIPTION

FileEntry is a composite widget for choosing files.
It features a L<Tk::Label>, L<Tk::Entry>, and a L<Tk::Button>. 

When the button is clicked, a dialog for choosing a file will show up.
The path of the chosen file will be inserted into the entry widget.
The label is intended as caption fot the entry widget.

This is useful if you want to provide a convenient way to select a
file path.




=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item C<Option:> B<-filebitmap>

=item C<Name:> B<fileBitmap>

=item C<Class:> B<FileBitmap>

Specifies the bitmap to be used for the button that invokes the File Dialog.

=item B<-command>

A callback that is executed when a file is chosen.

Pressing enter in the entry widget will execute this callback. See L<Tk::FileEntry/BINDINGS>.

=item B<-variable>

Reference to variable that will be bound to the value of the entry widget.
See C<Tk::options> for more details on C<-variable>.

=item B<-label>

Defines the label text. Defaults to I<File:>.

=back

=cut


# METHODS

sub ClassInit {
    my ($class, $mw) = @_;

    return if defined $FILEBITMAP;  # needed for several MainWindows
    $FILEBITMAP = __PACKAGE__ . '::OPENFOLDER';

    my $bits = pack("b16"x10,
        "...111111.......",
        "..1......11.....",
        ".1.........1....",
        ".1..........1...",
        ".1...11111111111",
        ".1..1.1.1.1.1.1.",
        ".1.1.1.1.1.1.1..",
        ".11.1.1.1.1.1...",
        ".1.1.1.1.1.1....",
        ".1111111111.....",
        );

    $mw->DefineBitmap($FILEBITMAP => 16,10, $bits);

}

sub Populate {
    my ($w,$args) = @_;

    $w->SUPER::Populate($args);

    my $l = $w->Label()->pack(-side=>'left');
    my $e = $w->Entry()->pack(-side=>'left', -expand=>'yes', -fill=>'x');
    my $b = $w->Button(
		-command => [\&_selectfile, $w, $e],
		-takefocus => 0,
	)->pack(
		-side => 'left',
		-fill => 'y',
	);

    $e->bind('<Return>', [$w, '_invoke_command', $e]);

    $w->Advertise('entry' => $e);
    $w->Advertise('button' => $b);

	$w->Delegates(
		'get' => $e,
		'insert' => $e,
		'delete' => $e,
		DEFAULT => $w,
	);
	
    $w->ConfigSpecs(
	    -background	=> [qw(CHILDREN background Background), Tk::NORMAL_BG()],
	    -foreground	=> [qw(CHILDREN foreground Foreground), Tk::BLACK()    ],
	    -state 	=> [qw(CHILDREN state      State        normal)        ],
	    -label       => [{-text => $l},   'label',      'Label',     'File:'],
	    -filebitmap  => [{-bitmap => $b}, 'fileBitmap', 'FileBitmap', $FILEBITMAP,],
	    -command	 => ['CALLBACK',       undef,        undef,       undef],
	    -variable    => ['METHOD',         undef,        undef,       undef],
	);
	
    return $w;
} # /populate




sub _selectfile {
    my $w = shift;
    my $e = shift;

	my $file = $w->getOpenFile();

    return unless defined $file && length $file;
    $e->delete(0,'end');
    $e->insert('end',$file);
    $w->Callback(-command => $w, $file);
}


sub _invoke_command {
    my $w = shift;
    my $e = shift;
    my $file = $e->get();
    return unless defined $file && length $file;
    $w->Callback(-command => $w, $e->get);
}


# variable( $v ) is listed as method in ConfigSpecs

sub variable {
    my $e = shift->Subwidget('entry');
    my $v = shift;
    $e->configure(-textvariable => $v);
}    




=head1 BINDINGS

C<Tk::FileEntry> has default bindings to allow the execution of the callback when a user presses enter in the entry widget.




=head1 EXAMPLE

  use strict;
  use warnings;
  use Tk;
  use Tk::FileEntry;
  
  my $mw = tkinit();
  
  $mw->FileEntry->pack(-expand => 1, -fill => 'x');
  
  $mw->MainLoop();



=head1 BUGS

None yet. If you find one, please consider creating a bug report, e.g. via L<Github|https://github.com/asb-capfan/Tk-FileEntry/issues>.




=head1 SEE ALSO

=over

=item * L<Tk::getOpenFile> for details about the file selection dialog

=item * L<Tk::Entry> for details about the Entry widget

=item * L<Tk> for details about the Perl/Tk GUI library

=back

There is a wiki for Tcl/Tk stuff on the web: L<http://wiki.tcl.tk/>




=head1 KEYWORDS

fileentry, tix, widget, file selector




=head1 AUTHOR

Alex Becker, E<lt>c a p f a n `a`t` g m x `d`o`t` d e - i n v a l i dE<gt>

Original Author was Achim Bohnet <ach@mpe.mpg.de>.

This code is inspired by the documentation of FileEntry.n of the Tix4.1.0 distribution by Ioi Lam.
The bitmap data are also from Tix4.1.0. For everything else:

=head1 COPYRIGHT

Copyright (C) 2013 by Alex Becker

Copyright (c) 1997-1998 Achim Bohnet. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut


1; # /Tk::FileEntry