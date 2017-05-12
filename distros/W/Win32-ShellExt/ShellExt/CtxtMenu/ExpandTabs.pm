# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::ExpandTabs;

use strict;
use Win32::ShellExt::CtxtMenu;
use Text::Tabs;
use Win32API::File 0.08 qw( :ALL );

$Win32::ShellExt::CtxtMenu::ExpandTabs::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::ExpandTabs::COMMAND="Expand tabs";
@Win32::ShellExt::CtxtMenu::ExpandTabs::ISA=qw(Win32::ShellExt::CtxtMenu);

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
	my $txtsonly = "Win32::ShellExt::CtxtMenu::ExpandTabs";
	my $item;

	foreach $item (@_) { undef $mp3sonly if($item!~m!\.txt$!); }

	$txtsonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.

	$tabstop = 4;
	map {
	  eval {
	    my ($in,$out) = ($_,"$_.expandtabs");
	    local *IN;
	    open IN,$in || die "cannot open file";
	    open OUT,">$out" || die "cannot open file";
	    while (<IN>) {
	      print OUT expand($_);
	    }
	    close IN;
	    MoveFileEx( $out, $in, MOVEFILE_REPLACE_EXISTING() );
	  }
	} @_;

	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{6A63F5AC-0D54-4162-9560-E4CD1C6BB123}",
	"name"  => "expand tabs shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::ExpandTabs"
	};
	$h;
}

1;


