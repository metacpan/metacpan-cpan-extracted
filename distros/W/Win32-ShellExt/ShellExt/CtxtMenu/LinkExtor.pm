# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::LinkExtor;

# extract a list of links from an HTML file an put it in the clipboard.

use strict;
use Win32::ShellExt::CtxtMenu;
use Win32::Clipboard;
use HTML::LinkExtor;
use URI::URL;

$Win32::ShellExt::CtxtMenu::LinkExtor::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::LinkExtor::COMMAND="Extract links from HTML into clipboard";
@Win32::ShellExt::CtxtMenu::LinkExtor::ISA=qw(Win32::ShellExt::CtxtMenu);

sub query_context_menu() {
	my $self = shift;

	my $s = "Win32::ShellExt::CtxtMenu::LinkExtor";
	my $item;

	foreach $item (@_) { undef $s if($item!~m!\.html$!i); }

	$s;
}

my @links = ();
sub callback {
  my($tag, %attr) = @_;
  return if $tag ne 'a';
  push(@imgs, values %attr);
}

sub extract_links() {
  my ($self,$html) = @_;

  # Make the parser.  Unfortunately, we don't know the base yet
  # (it might be diffent from $url)
  my $p = HTML::LinkExtor->new(\&callback);
  $p->parse_file($html);

  # Expand all URLs to absolute ones
  my $base = $res->base;
  @links = map { $_ = url($_, $base)->abs; } @links;

}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.

	map { $self->extract_links($_); } @_;

	my $CLIP = Win32::Clipboard();
	$CLIP->Set(join '\n',@links);
	1;
}

sub hkeys() {
	my $h = {
	"CLSID" => "{D9AFF54E-056C-4582-93D9-86BB9054A4A5}",
	"name"  => "link extraction shell Extension",
	"package" => "Win32::ShellExt::CtxtMenu::LinkExtor"
	};
	$h;
}

1;
