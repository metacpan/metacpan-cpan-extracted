# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::MD5;

# generate MD5 signature for a file into a new file.
# TODO: add command to generate signature into clipboard.

use strict;
use Win32::ShellExt::CtxtMenu;
use MD5;

# strip whitespace from a file.

$Win32::ShellExt::CtxtMenu::MD5::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::MD5::COMMAND="generate MD5 digest";
@Win32::ShellExt::CtxtMenu::MD5::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $txtsonly = "Win32::ShellExt::CtxtMenu::MD5";
	my $item;

	foreach $item (@_) { undef $txtsonly if($item!~m!\.txt$!); }
	$txtsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	

	map {

	  my $md5 = new MD5;
	  $md5->reset();
	  $md5->add($_);
	  my $digest = $md5->hexdigest();

	  my $out = $_;
	  $out =~ s!\.txt$!\.md5!g;
	  open OUT, ">$out";
	  print OUT $digest;
	  close OUT;
	} @_;
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{B22156F2-2D36-469D-8E02-4C1DB72EA213}",
	"name"  => "md5 shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::MD5"
	};
	$h;
}

1;

