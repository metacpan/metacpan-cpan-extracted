# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::RegisterDll;

use strict;
use Win32::ShellExt::CtxtMenu;

$Win32::ShellExt::CtxtMenu::RegisterDll::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::RegisterDll::COMMAND="Register DLL";
@Win32::ShellExt::CtxtMenu::RegisterDll::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $dllsonly = "Win32::ShellExt::CtxtMenu::RegisterDll";

	my $item;
	foreach $item (@_) { undef $dllsonly if($item!~m!\.dll$!); }

	$dllsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.

	map {
	  Win32::RegisterServer($_);
	} @_;

	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{9A6D7868-65A6-4A2A-9DBC-0387D8E96EAB}",
	"name"  => "register DLL shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::RegisterDll"
	};
	$h;
}

1;


