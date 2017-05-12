#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) ? 1 : 2;

BEGIN {
    use_ok( 'Tk::JDialog' ) || print "Bail out!\n";
}

diag( "Testing Tk::JDialog $Tk::JDialog::VERSION, Perl $], $^X" );

sub sam {
	my $mw = eval { MainWindow->new( -title => 'Test' ) };
	return 1  unless ($mw);    #PREVENT TEST FAILURE IF NO X-SERVER RUNNING.
	my $Dialog = $mw->JDialog(
	     -title          => 'Choose!',   #DISPLAY A WINDOW TITLE
	     -text           => 'Press Ok to Continue',  #DISPLAY A CAPTION
	     -bitmap         => 'info',      #DISPLAY BUILT-IN info BITMAP.
	     -default_button => '~Ok',
	     -escape_button  => '~Cancel',
	     -buttons        => ['~Ok', '~Cancel', '~Quit'], #DISPLAY 3 BUTTONS
	);
	my $button_label = $Dialog->Show();
	return ($button_label =~ /\~(?:Ok|Cancel|Quit)$/) ? 1 : 0;
}

#&sam() ? print "not ok 2\n" : print "ok 2\n";
#print "..done: 2 tests completed.\n";
unless ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) {
	is(&sam(), 1, 'running Tk::JDialog sample program.');
	diag( "Testing sample Tk::JDialog program." );
}

__END__
