# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::UnregisterDll;

use strict;
use Win32::ShellExt::CtxtMenu;

$Win32::ShellExt::CtxtMenu::UnregisterDll::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::UnregisterDll::COMMAND="Register DLL";
@Win32::ShellExt::CtxtMenu::UnregisterDll::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $dllsonly = "Win32::ShellExt::CtxtMenu::UnregisterDll";

	my $item;
	foreach $item (@_) { undef $dllsonly if($item!~m!\.dll$!); }

	$dllsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.

	map {
	  Win32::UnregisterServer($_);
	} @_;

	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{6DED00C2-B98B-4ED9-AA7F-4AEF05C9604D}",
	"name"  => "unregister DLL shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::UnregisterDll"
	};
	$h;
}

1;


