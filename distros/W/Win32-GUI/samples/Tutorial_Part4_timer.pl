#!perl -w
use strict;
use warnings;

use Win32::GUI();

my $main = Win32::GUI::Window->new(
	-name => 'Main',
	-text => 'Perl',
	-width => 200,
       	-height => 200
);

my $t1 = $main->AddTimer('T1', 1000);

    
$main->Show();
Win32::GUI::Dialog();
exit(0);

sub Main_Terminate {
	return -1;
}

sub T1_Timer {
	print "Timer went off!\n";
	return 0;
}
