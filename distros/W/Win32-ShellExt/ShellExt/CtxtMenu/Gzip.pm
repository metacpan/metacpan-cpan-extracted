# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::Gzip;

use strict;
use Win32::ShellExt::CtxtMenu;
use Compress::Zlib;

$Win32::ShellExt::CtxtMenu::Gzip::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::Gzip::COMMAND="Gzip";
@Win32::ShellExt::CtxtMenu::Gzip::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	my $noz = "Win32::ShellExt::CtxtMenu::Gzip";
	my $item;

	foreach $item (@_) { undef $noz if($item=~m!\.g?z$!i); } # don't try to zip if it's already compressed.

	$noz;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.

	map {
	  eval {
	    my $file = $_;
	    my $buffer;
	    my $gz = gzopen("$file.gz", "rb") 
	      or die "Cannot open $file.gz: $gzerrno\n" ;
	    local *F;
	    my $fn = $_;
	    open F, "$file";
	    while (<F>) {
	      $gz->gzwrite($_);
	    }
	    close F;
	    $gz->gzclose() ;
	  }
	} @_;

	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{50E828A5-C3D1-4918-9FFC-5F55155716BE}",
	"name"  => "Gzip file compression shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::Gzip"
	};
	$h;
}

1;



