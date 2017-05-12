# -*- cperl -*-
#
# (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
#
package Win32::ShellExt::CanonicalXML;

# This extension canonicalizes XML files.

use strict;
use Win32::ShellExt;
use XML::Canonical;

$Win32::ShellExt::CanonicalXML::VERSION='0.1';
$Win32::ShellExt::CanonicalXML::TEXT="Rename using Win32::ShellExt::CanonicalXML";
@Win32::ShellExt::CanonicalXML::ISA=qw(Win32::ShellExt);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.	
	my $xmlonly = "Win32::ShellExt::CanonicalXML";
	my $item;

	foreach $item (@_) { undef $xmlonly if($item!~m!\.xml!); }
	$xmlonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	
	
	map {
	  eval {
	    my $canon = XML::Canonical->new(comments => 1);
	    my $canon_xml = $canon->canonicalize_document($_);
	    $_ =~ s!\.xml$!\.canonical\.xml!;
	    local *OUT;
	    open OUT,">$_";
	    print OUT $canon_xml;
	    close OUT;
	  }
	} @_;
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{248D1EC0-0D4F-4A37-A661-D774840A2ED6}",
	"name"  => "canonical XML shell Extension",
	"alias" => "canonical_xml_menu",
	"package" => "Win32::ShellExt::CanonicalXML"
	};
	$h;
}

1;
