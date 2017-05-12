# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::Gunzip;

use strict;
use Win32::ShellExt::CtxtMenu;
use Compress::Zlib;

$Win32::ShellExt::CtxtMenu::Gunzip::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::Gunzip::COMMAND="Uncompress";
@Win32::ShellExt::CtxtMenu::Gunzip::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $zsonly = 	"Win32::ShellExt::CtxtMenu::Gunzip";
	my $item;

	foreach $item (@_) { undef $zsonly if($item!~m!\.g?z$!i); }

	$zsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	
	
	map {
	  eval {
	    my $file = $_;
	    my $buffer;
	    my $gz = gzopen($file, "rb") 
	      or die "Cannot open $file: $gzerrno\n" ;
	    local *F;
	    my $fn = $_;
	    $fn =~ s!\.(gz|z|Z)$!!g;
	    open F, ">$fn";
	    print F $buffer 
	      while $gz->gzread($buffer) > 0 ;
	    die "Error reading from $file: $gzerrno\n" if $gzerrno != Z_STREAM_END ;
	    close F;
	    $gz->gzclose() ;
	  }
	} @_;

	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{EC2268F1-54E4-4326-88F7-A69BAB55E14F}",
	"name"  => "Gunzip file compression shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::Gunzip"
	};
	$h;
}

1;



