# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::RenameMP3;

# Look at http://freshmeat.net/redir/mp3mover/13777/url_homepage
# for an alternate way of doing the same thing differently.
# I prefer this script rather than mp3mover because it's integrated
# into the Explorer.

use strict;
use Win32::ShellExt::CtxtMenu;

use MP3::Info qw(:all);
use Win32API::File 0.08 qw( :ALL );

$Win32::ShellExt::CtxtMenu::RenameMP3::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::RenameMP3::COMMAND="Rename using Win32::ShellExt::CtxtMenu::RenameMP3";
@Win32::ShellExt::CtxtMenu::RenameMP3::ISA=qw(Win32::ShellExt::CtxtMenu);

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
	my $mp3sonly = "Win32::ShellExt::CtxtMenu::RenameMP3";
	my $item;

	foreach $item (@_) { undef $mp3sonly if($item!~m!\.mp3$!); }

	$mp3sonly;
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	

	my $f;
	while($f = pop @_) {
	  eval {
	    my $tag = get_mp3tag($f) or die "No TAG info";
	    my $path = $f;
	    $path =~ s!\\[^\\]+$!!g;
	    my $tgt = $path . "\\" . $tag->{ARTIST} . " - " . $tag->{ALBUM} . " - " . $tag->{TITLE} . ".mp3";

	    MoveFile( $f, $tgt );
	  }
	}

	# do nothing in the base class for extensions.
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{3FEE610F-2262-4d0b-85A4-68F733538022}",
	"name"  => "mp3 file renaming shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::RenameMP3"
	};
	$h;
}

1;


