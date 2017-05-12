#!perl -w
use strict;
use warnings;
# $Id: DropFilesDemo.pl,v 1.1 2006/04/25 21:38:19 robertemay Exp $
#
# Demonstration of Win32::GUI::DropFiles functionality
#
# Note that even though Win32::GUI::DropFiles supports
# Unicode filenames on WinNT and above, Win32::GUI::Listbox
# does not, so filenames with unicode characters will appear
# corrupted in this demo.

use Win32::GUI();
use Win32::GUI::DropFiles();

my $mw = Win32::GUI::Window->new(
	-title => "Win32::GUI::DropFiles Demonstration",
	-pos   => [100,100],
	-size  => [400,300],
	-onResize => \&mwResize,
);

$mw->AddLabel(
	-pos  => [10,10],
	-text => "Drag files onto the Listbox below:",
);

$mw->AddListbox(
	-name => 'LB',
	-pos => [10,30],
	-vscroll => 1,
	-acceptfiles => 1,
	-onDropFiles => \&gotDrop,
);

$mw->Show();
Win32::GUI::Dialog();
$mw->Hide();
exit(0);

sub gotDrop {
	my ($self, $dropObj) = @_;

	$self->Add($dropObj->GetDroppedFiles());

	return 0;
}

sub mwResize {
	my $self = shift;

	$self->LB->Resize(
		$self->ScaleWidth()-20,
		$self->ScaleHeight()-40,
	);

	return 1;
}
