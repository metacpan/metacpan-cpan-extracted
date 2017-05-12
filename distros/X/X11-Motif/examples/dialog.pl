#!/ford/thishost/unix/div/ap/bin/perl5.00404 -w

use blib;

use strict;
use X11::Motif;

my $toplevel = X::Toolkit::initialize("Dialog");

my $form = give $toplevel -Form;
my $hello = give $form -Label, -text => 'Click button to popup dialog';
my $ok = give $form -Button, -text => 'Popup!', -command => \&do_popup;

arrange $form -fill => 'xy', -bottom => [ $ok, $hello ];

handle $toplevel;

sub do_popup {
    give $toplevel -Dialog,
	-type => -question,
	-title => 'title here',
	-ok => [ 'Yes' => sub { print "yes?  are you sure?\n" } ],
	-cancel => [ 'No' => sub { print "no?  why not?\n" } ],
#	-cancel => \&do_cancel,
	-message => 'Do you like your job?';
}

sub do_cancel {
}
