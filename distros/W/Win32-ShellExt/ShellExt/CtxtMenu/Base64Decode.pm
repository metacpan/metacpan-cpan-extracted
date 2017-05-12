# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::Base64Decode;

use strict;
use Win32::ShellExt::CtxtMenu;
use MIME::Base64 qw(decode_base64);

$Win32::ShellExt::CtxtMenu::Base64Decode::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::Base64Decode::COMMAND="Decode as Base64";
@Win32::ShellExt::CtxtMenu::Base64Decode::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $uuesonly = "Win32::ShellExt::CtxtMenu::Base64Decode";
	my $item;

	foreach $item (@_) { undef $uuesonly if($item!~m!\.uue$!); }

	$uuesonly;
}

sub action() {
  my $self = shift;
  # @_ now holds the list of file paths we want to act on.	
  
  map {
    eval {
      local *IN;
      local *OUT;
      open(IN, $_) or die "$!";
      my $outfile=$_;
      $outfile=~s!uue$!!g;
      open OUT, ">$outfile" or die "$!";
      my $buf;
      while (read(IN, $buf, 60*57)) {
	print OUT decode_base64($buf);
      }
      close IN;
      close OUT;
    }
  } @_;
  
} 

sub hkeys() {
	my $h = {
	"CLSID" => "{A5E47D16-58D6-4CAD-92D9-9244528193F4}",
	"name"  => "base64 decode shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::Base64Decode"
	};
	$h;
}

1;
