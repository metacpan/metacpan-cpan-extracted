# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::Zip;

use Archive::Zip;
use Win32::ShellExt::CtxtMenu;

$Win32::ShellExt::CtxtMenu::Zip::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::Zip::COMMAND="Extract using Win32::ShellExt::CtxtMenu::Zip";
@Win32::ShellExt::CtxtMenu::Zip::ISA=qw(Win32::ShellExt::CtxtMenu);

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
	my $zipsonly = "Win32::ShellExt::CtxtMenu::Zip";
	my $item;

	foreach $item (@_) { undef $zipsonly if($item!~m!\.zip!); }

	$zipsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	

	map {
	  eval {
	    my $zip = Archive::Zip->new();
	    my $status = $zip->read( $_ );
	    die "Read of $zipName failed\n" if $status != AZ_OK;

	    my @members = $zip->members();
	    map { $zip->extractMember($_); } (@members)
	  }
	} @_;

	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{A38F48C7-41B4-4394-BB66-5ECE6F832D1B}",
	"name"  => "Zip shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::Zip"
	};
	$h;
}

1;
