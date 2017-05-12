use Test::More tests => 2;
BEGIN {use_ok("Tk::Help")};

use strict;
use warnings;

use Tk;
use Tk::Help;

my @helparray = ([{-title  => "Test Help",
				  -header => "My Test Help",
				  -text	  => "Test help description."}],
				[{-title  => "Section 1",
				  -header => "Section 1 Help",
				  -text	  => "This is a description of section 1."},
				 {-title  => "1st Feature",
				  -header => "The 1st Feature",
				  -text	  => "This is the text describing the 1st feature of section 1."},
				 {-title  => "2nd Feature",
				  -header => "The 2nd Feature",
				  -text	  => "This is the text describing the 2nd feature of section 1."}],
				[{-title  => "Section 2",
				  -header => "Section 2 Help",
				  -text	  => "This is a description of section 2."},
				 {-title  => "1st Feature",
				  -header => "The 1st Feature",
				  -text	  => "This is the text describing the 1st feature of section 2."},
				 {-title  => "2nd Feature",
				  -header => "The 2nd Feature",
				  -text	  => "This is the text describing the 2nd feature of section 2."}]);

my $main = MainWindow->new();

my $help = $main->Help(-title	 => "Test Help",
					   -variable => \@helparray);

ok($help->class eq "Help", "Verify creation of help");