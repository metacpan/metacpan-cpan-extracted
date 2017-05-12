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

$W1->AddButton(
	-name => "Button1",
	-text => "Open popup window",
	-pos  => [ 10, 10 ],
);

my $W2 = Win32::GUI::Window->new(
	-name  => "W2",
	-title => "Second Window",
	-pos   => [ 150, 150 ],
	-size  => [ 300, 200 ],
	-parent => $W1,
);

$W2->AddButton(
	-name => "Button2",
	-text => "Close this window",
	-pos  => [ 10, 10 ],
);

$W1->Show();
Win32::GUI::Dialog();
exit(0);

sub W1_Terminate {
	return -1;
}

sub Button1_Click {
	$W2->DoModal();
	return 0;
}

sub W2_Terminate {
	return -1;
}

sub Button2_Click {
	return -1;
}
