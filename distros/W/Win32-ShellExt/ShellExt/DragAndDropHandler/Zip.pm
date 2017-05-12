# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::DragAndDropHandler::Zip;

use Archive::Zip;
use Win32::ShellExt::DragAndDropHandler;

$Win32::ShellExt::DragAndDropHandler::Zip::VERSION='0.1';
$Win32::ShellExt::DragAndDropHandler::Zip::COMMAND="dump Zip archive members to text file";
@Win32::ShellExt::DragAndDropHandler::Zip::ISA=qw(Win32::ShellExt::DragAndDropHandler);

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
	my $zipsonly = "Win32::ShellExt::DragAndDropHandler::Zip";
	my $item;

	foreach $item (@_) { undef $zipsonly if($item!~m!\.zip!); }

	$zipsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.

	map {
	  eval {
	    local *F;
	    my $f = "$_.ziplist";

	    my $zip = Archive::Zip->new();
	    my $status = $zip->read($file);
	    if($status == AZ_OK) {
	      open F,">$f";
	      foreach my $member ($zip->members())
		{
		  if($member->uncompressedSize()!=0) { # this skips over directories.
		    print F $member->fileName();
		    print F " (";
		    print F $member->uncompressedSize();
		    print F "/";
		    print F $member->compressedSize();
		    print F ")\n";
		  }
		}
	      close F;
	    }
	  }
	} @_;

	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{3E15D28B-F451-41CC-8AF9-F5065A897B99}",
	"name"  => "DnD Zip shell Extension",
	"package" => "Win32::ShellExt::DragAndDropHandler::Zip"
	};
	$h;
}

1;
