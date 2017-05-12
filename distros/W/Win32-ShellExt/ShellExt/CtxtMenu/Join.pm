# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::Join;

#
# when several files are selected, and they have a common naming
# scheme this extension allows you to join those files into one
# big one (this applies for instance to files that you get using the
# unix 'split' command).
#
# The C++ (ATL-based) extension that you'll find at
# http://home.worldonline.dk/~viksoe/ctxmenu.htm
# seem to do the same kind of thing.
#

use strict;
use Win32::ShellExt::CtxtMenu;

use Text::Trie qw(Trie);

$Win32::ShellExt::CtxtMenu::Join::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::Join::COMMAND="Join files";
@Win32::ShellExt::CtxtMenu::Join::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	"Win32::ShellExt::CtxtMenu::Join";
}

sub action() {
	my $self = shift;
	return if $#_<2;

	# find common leading string in selected files.
  	my $s = shift Trie @_;
	if(length($s)>0) {
	  local *OUT;
	  local *IN;
	  open OUT,">$s";
	  my $k;
	  foreach $k (@_) { # a very inefficient way of copying a file's contents to another.
	    open IN,$k;
	    while (<IN>) {
	      print OUT $_;
	    }
	    close IN;
	  }
	  close OUT;
	}
}

sub hkeys() {
	my $h = {
	"CLSID" => "{A89266A9-6895-465C-AFF5-483F11AEAA74}",
	"name"  => "join files shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::Join"
	};
	$h;
}

1;


