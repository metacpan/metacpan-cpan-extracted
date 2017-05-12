#!perl -w
use strict;
use warnings;

use Win32::GUI();

my $main = Win32::GUI::DialogBox->new(
	-name => 'Main',
	-text => 'Perl',
	-width => 200,
       	-height => 200
);

$main->AddButton(
	-name    => 'Default',
	-text    => 'Ok',
	-default => 1,    # Give button darker border
	-ok      => 1,    # press 'Return' to click this button
	-width   => 60,
	-height  => 20,
	-left    => $main->ScaleWidth() - 140,
	-top     => $main->ScaleHeight() - 30,
);

$main->AddButton(
	-name   => 'Cancel',
	-text   => 'Cancel',
	-cancel => 1,    # press 'Esc' to click this button
	-width  => 60,
	-height => 20,
	-left   => $main->ScaleWidth() - 70,
	-top    => $main->ScaleHeight() - 30,
);

$main->Show();
Win32::GUI::Dialog();
exit(0);

sub Main_Terminate {
	return -1;
}

sub Default_Click {
	print "Default button clicked\n";
	return 0;
}

sub Cancel_Click {
	print "Cancel button clicked\n";
	return 0;
}
