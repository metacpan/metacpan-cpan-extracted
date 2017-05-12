# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::Tgz;

# Extracts .tar files.

use strict;
use Win32::ShellExt;
use Archive::Tar;
use Compress::Zlib;

$Win32::ShellExt::Tgz::VERSION='0.1';
$Win32::ShellExt::Tgz::TEXT="extract using Archive::Tgz";
@Win32::ShellExt::Tgz::ISA=qw(Win32::ShellExt);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $tgzsonly = "Win32::ShellExt::Tgz";
	my $item;

	foreach $item (@_) { undef $tgzsonly if($item!~m!\.t(ar\.)?gz$!); }
	$tgzsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.

	map {
	  FIXME first use Compress::Zlib to unpack the gzipped contents.

	  Archive::Tar->new()->extract_archive($_);
	} @_;

	# do nothing in the base class for extensions.
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{97fc58cf-9747-40ba-861a-85ef40e42031}",
	"name"  => "tgz shell Extension",
	"package" => "Win32::ShellExt::Tgz"
	};
	$h;
}

1;




