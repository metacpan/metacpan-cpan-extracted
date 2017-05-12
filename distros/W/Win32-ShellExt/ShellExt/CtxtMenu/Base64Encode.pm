# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::Base64Encode;

use strict;
use Win32::ShellExt::CtxtMenu;
use MIME::Base64 qw(encode_base64);

$Win32::ShellExt::CtxtMenu::Base64Encode::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::Base64Encode::COMMAND="Encode as Base64";
@Win32::ShellExt::CtxtMenu::Base64Encode::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	my $s = "Win32::ShellExt::CtxtMenu::Base64Encode";
	$s;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	

	map {
	  eval {
	    local *IN;
	    local *OUT;
	    open(IN, $_) or die "$!";
	    open OUT, ">$_.uue" or die "$!";
	    while (<IN>) {
	      print OUT encode_base64($_);
	    }
	    close IN;
	    close OUT;
	  }
	} @_;
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{49D1EDC1-11A4-426D-818A-88588E57195C}",
	"name"  => "base64 encode shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::Base64Encode"
	};
	$h;
}

1;
