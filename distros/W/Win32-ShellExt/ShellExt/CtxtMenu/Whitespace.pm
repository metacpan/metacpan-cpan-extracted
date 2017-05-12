# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::Whitespace;

use strict;
use Win32::ShellExt::CtxtMenu;
use Whitespace;

# strip whitespace from a file.

$Win32::ShellExt::CtxtMenu::Whitespace::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::Whitespace::COMMAND="strip whitespace out of text file";
@Win32::ShellExt::CtxtMenu::Whitespace::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $txtsonly = "Win32::ShellExt::CtxtMenu::Whitespace";
	my $item;

	foreach $item (@_) { undef $txtsonly if($item!~m!\.txt$!); }
	$txtsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	
	
	map {

	  # Instantiate a whitespace object with
	  # both input and output files specified
	  my $outfile = $_;
	  $outfile =~ s!\.txt$!\.stripped\.txt!g;
	  my $ws = new Whitespace($_, $outfile);

	  # Detect the whitespaces
	  my $ret = $ws->detect();

	  $ret = $ws->cleanup();

	} @_;
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{1BCE0D43-5ACC-4FB3-A6D8-A69D9267D74F}",
	"name"  => "whitespace shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::Whitespace"
	};
	$h;
}

1;

