# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::CopyPath;

#
# See http://www.codeguru.com/shell/CopyPathShellExt.shtml
# for an implementation in C++ of this extension. That's where
# the idea came from, this one is just an example of how to
# implement the same thing in Perl with Win32::ShellExt::CtxtMenu (no code
# is common with that c++ 'CopyPath' code, though).
#
# This is also similar to 'Path Copy' which i found at
# http://www.simtel.net/pub/dl/57104.shtml
# after writing this!
# The 'Clickie' utility at http://defoort.free.fr/clickie/clickie.exe
# also does the same thing.
#
# Also see http://www.codeproject.com/shell/copypathext.asp
# and http://www.mainsoft.fr/files/clipname.zip
# apparently everyone's rewriting that same extension over and over
# again...
#

use strict;
use Win32::ShellExt::CtxtMenu;
use Win32::Clipboard;

$Win32::ShellExt::CtxtMenu::CopyPath::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::CopyPath::COMMAND="Copy path to clipboard";
@Win32::ShellExt::CtxtMenu::CopyPath::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $s = "Win32::ShellExt::CtxtMenu::CopyPath";
	$s;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.

	my $CLIP = Win32::Clipboard();
	$CLIP->Set(join '\n',@_);
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{E06853EF-4421-409C-BCFE-B2A048536F67}",
	"name"  => "copy path shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::CopyPath"
	};
	$h;
}

1;


