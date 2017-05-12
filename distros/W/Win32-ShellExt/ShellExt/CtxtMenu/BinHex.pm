# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::BinHex;

use strict;
use Win32::ShellExt::CtxtMenu;

use Convert::BinHex 1.119;

$Win32::ShellExt::CtxtMenu::BinHex::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::BinHex::COMMAND="Extract BinHex";
@Win32::ShellExt::CtxtMenu::BinHex::ISA=qw(Win32::ShellExt::CtxtMenu);

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
	my $hqxonly = "Win32::ShellExt::CtxtMenu::BinHex";
	my $item;

	foreach $item (@_) { undef $hqxonly if($item!~m!\.hqx!); }

	$hqxonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	

	map {
	  eval {
	    my ($in,$out) = ($_,$_);
	    $out =~ s!\.hqx!!g;
	    my $H2B = Convert::BinHex->hex2bin;    # get a converter object
	    local *IN;
	    open IN,$in;
	    open OUT,">$out";
	    while (<IN>) {
	      print OUT $H2B->next($_);        # convert some more input
	    }
	    print OUT $H2B->done;              # no more input: finish up
	    close IN;
	    close OUT;
	  }
	} @_;
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{A0A05EF0-620A-4ACC-B5E5-E500622E9E8F}",
	"name"  => "binhex shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::BinHex"
	};
	$h;
}

1;


