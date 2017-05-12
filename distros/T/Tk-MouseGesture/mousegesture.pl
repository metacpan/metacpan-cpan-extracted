# MouseGesture.pm - invoke callbacks via mouse gestures
#!perl -w

use strict;
use Tk;
use Tk::MouseGesture;
use Tk::NoteBook;

my $mw = new MainWindow;
$mw->geometry("700x400");

my $nb = $mw->NoteBook->pack(qw/-fill both -expand 1/);
my $pp = $nb->add("TEST", -label => 'Usage');
$pp->Label(-text => <<EOT, -justify => 'left', -font => ['courier', 10])->pack;
This page can not be deleted!

Mouse Gestures:
New Page:            Hold down right button, and drag mouse vertically upwards.
Kill Page:           Hold down right button, and drag mouse vertically downwards.
Go Back One Page:    Hold down right button, and drag mouse horizontally left.
Go Forward One Page: Hold down right button, and drag mouse horizontally right.

EOT
;

my $cnt = 1;

# create gesture to add new page.
$mw->MouseGesture('B3-up', -command => sub {
		    $nb->add("C$cnt", -label => "C$cnt");
		    $nb->raise("C$cnt");
		    $cnt++;
		  });

$mw->MouseGesture('B3-down', -command => sub {
		    my $page = $nb->raised;
		    return unless $page;
		    return if $page eq 'TEST';

		    $nb->delete($page);
		  });

$mw->MouseGesture('B3-left', -command => sub {
		    my $page = $nb->raised;
		    my @all  = $nb->pages;

		    my $i = 0;
		    $_ eq $page && last, $i++for @all;

		    return if $i == 0;

		    $nb->raise($all[$i-1]);
		  });

$mw->MouseGesture('B3-right', -command => sub {
		    my $page = $nb->raised;
		    my @all  = $nb->pages;

		    my $i = 0;
		    $_ eq $page && last, $i++for @all;

		    return if $i == $#all;

		    $nb->raise($all[$i+1]);
		  });

MainLoop;

__END__
