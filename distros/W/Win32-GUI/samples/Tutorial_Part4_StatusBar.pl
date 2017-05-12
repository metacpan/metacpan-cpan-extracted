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

my $sb = $main->AddStatusBar();

$main->Show();
Win32::GUI::Dialog();
exit(0);

sub Main_Terminate {
	return -1;
}

sub Main_Resize {
	$sb->Move( 0, ($main->ScaleHeight() - $sb->Height()) );
	$sb->Resize( $main->ScaleWidth(), $sb->Height() );
	$sb->Text( "Window size: " . $main->Width() . "x" . $main->Height() );
	return 0;
}
