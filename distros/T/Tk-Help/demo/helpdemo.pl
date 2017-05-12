#!/usr/bin/perl --

use strict;
use warnings;

use Tk;
use Tk::Help;

# create the main window for the demo
my $main = MainWindow->new(-title => "My Application");
# create the menubar for the main window
$main->configure(-menu => my $menubar = $main->Menu);

# add the file and help menus to the menubar
my $filemenu = $menubar->cascade(-label   => "~File",
								 -tearoff => 0);
my $helpmenu = $menubar->cascade(-label   => "~Help",
								 -tearoff => 0);
# add the exit command to the file menu and the help command to the help menu
$filemenu->command(-label	=> "E~xit",
				   -command => sub{$main->destroy});
$helpmenu->command(-label	=> "~Help Contents",
				   -command => sub{showhelp()});

MainLoop;

1;

sub showhelp {
	# create the array of help contents to pass to the help module
	my @helparray = ([{-title  => "My Application",
					   -header => "My Application Help",
					   -text   => "This is a description of my application for the help."}],
					 [{-title  => "Section 1",
					   -header => "\n\nSection 1 Help",
					   -text   => ""},
					  {-title  => "1st Feature",
					   -header => "The 1st Feature",
					   -text   => "This is the text describing the 1st feature of section 1."},
					  {-title  => "2nd Feature",
					   -header => "The 2nd Feature",
					   -text   => "This is the text describing the 2nd feature of section 1."}],
					 [{-title  => "Section 2",
					   -header => "\n\nSection 2 Help",
					   -text   => ""},
					  {-title  => "1st Feature",
					   -header => "The 1st Feature",
					   -text   => "This is the text describing the 1st feature of section 2."},
					  {-title  => "2nd Feature",
					   -header => "The 2nd Feature",
					   -text   => "This is the text describing the 2nd feature of section 2."}]);

	# create the help object
	my $help = $main->Help(-title	 => "My Application - Help",
						   -variable => \@helparray);
}