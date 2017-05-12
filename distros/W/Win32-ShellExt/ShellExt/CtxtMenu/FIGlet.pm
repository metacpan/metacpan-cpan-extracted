# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::FIGlet;

#
# A sample shell extension that figlet-izes a text file.
# This is pretty slow on bigger files.
# Also the location of the 'standard.flf' file is hard-coded: this
# should be changed to a registry setting shared with Text::FIGlet, IMHO.
#
# One wonders how you could ever live till then without this! ;-)
#

use strict;
use Win32::ShellExt::CtxtMenu;

use Text::FIGlet;

$Win32::ShellExt::CtxtMenu::FIGlet::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::FIGlet::COMMAND="FIGlet-ize";
@Win32::ShellExt::CtxtMenu::FIGlet::ISA=qw(Win32::ShellExt::CtxtMenu);

sub new() {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);
  return $self;
}

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $txtsonly = "Win32::ShellExt::CtxtMenu::FIGlet";
	my $item;

	foreach $item (@_) { undef $txtsonly if($item!~m!\.txt!); }

	$txtsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	

	my $f;
	while($f = pop @_) {
	  eval {
	    my $path = $f;
	    $path .= ".figlet.txt";

	    my $in;
	    {
	      local $/; local *IN;
	      open IN,$f;
	      $in = <IN>;
	      close IN;
	    }
	    
	    local *OUT;
	    open OUT,">$path";
	    print OUT Text::FIGlet->new(-d=>'d:/build/perl/Text-FIGlet-1.05')->figify(-A=>$in, -m=>-1);
            close OUT;
	  }
	}

	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{8DFDEE29-021D-49A1-AD5F-AEE95EA6B291}",
	"name"  => "FIGlet shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::FIGlet"
	};
	$h;
}

1;
