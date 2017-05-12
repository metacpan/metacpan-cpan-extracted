# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::Tar;

# Extracts .tar files.

use strict;
use Win32::ShellExt::CtxtMenu;
use Archive::Tar;

$Win32::ShellExt::CtxtMenu::Tar::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::Tar::COMMAND="extract using Archive::Tar";
@Win32::ShellExt::CtxtMenu::Tar::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $tarsonly = "Win32::ShellExt::CtxtMenu::Tar";
	my $item;

	foreach $item (@_) { undef $tarsonly if($item!~m!\.tar$!); }
	$tarsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	

	map {
	  Archive::Tar->new()->extract_archive($_);
	} @_;

	# do nothing in the base class for extensions.
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{6762B07B-7810-4D99-959F-D38AC76FC9D9}",
	"name"  => "tar shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::Tar"
	};
	$h;
}

1;


