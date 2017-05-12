#!perl -w
use strict;
use warnings;

use Win32::GUI();

my $W1 = Win32::GUI::Window->new(
	-name  => "W1",
	-title => "First Window",
	-pos   => [ 100, 100 ],
	-size  => [ 300, 200 ],
);

my $W2 = Win32::GUI::Window->new(
	-name  => "W2",
	-title => "Second Window",
	-pos   => [ 150, 150 ],
	-size  => [ 300, 200 ],
);

$W1->Show();
$W2->Show();

Win32::GUI::Dialog();
exit(0);

sub W1_Terminate {
	return -1;
}

sub W2_Terminate {
	return -1;
}
