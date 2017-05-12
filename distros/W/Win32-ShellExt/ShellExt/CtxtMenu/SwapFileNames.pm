# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::SwapFileNames;

# See http://www.codeproject.com/shell/shswapl.asp , that's where the idea came from.

use strict;
use Win32::ShellExt::CtxtMenu;
use Win32::Clipboard;

$Win32::ShellExt::CtxtMenu::SwapFileNames::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::SwapFileNames::COMMAND="Swap Filenames";
@Win32::ShellExt::CtxtMenu::SwapFileNames::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $s = "Win32::ShellExt::CtxtMenu::SwapFileNames";

	if($#_==1) { # $#_ is maximum index, 1 means length is 2.
	  $s;
	} else {
	  undef;
	}
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	

	if($#_ == 1) { # only work on an even number of selected files.
	  my($f1,$f2) = @_;
	  my $tmp = $f1;
	  $tmp =~ s!:.*\\([^\\]*)$!:\\tmp$1!g;
	  rename $f1,$tmp;
	  rename $f2,$f1;
	  rename $tmp,$f2;
	} # I know this sucks, but it's enough to prove the point. Feel free to improve on it, though.

	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{06CA47EA-EFBB-426A-AD18-9F5069478498}",
	"name"  => "swap file names shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::SwapFileNames"
	};
	$h;
}

1;



