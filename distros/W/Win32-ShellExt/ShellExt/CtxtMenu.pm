# -*- cperl -*-
# Win32/ShellExt/CtxtMenu.pm
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::CtxtMenu;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt;
$Win32::ShellExt::CtxtMenu::VERSION = '0.1';
@Win32::ShellExt::CtxtMenu::ISA = qw(Win32::ShellExt);

use Config; # to locate where the DLL is installed.
use Win32::TieRegistry 0.23 ( Delimiter=>"/", ArrayValues=>1 ); # used for creation/deletion of registry keys for a given extension.
# tested with version 0.23 of Win32::TieRegistry.

# objects of that class are hashes, so that you can store your own data on instances of subclasses,
# between the query_context_menu() and action() calls, if needed.
sub new() {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);
  return $self;
}

# 'query_context_menu' and 'action' are the methods that should override in your
# specific extension.
sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	"";
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.	

	# do nothing in the base class for extensions.
	1;
}

#
# Here's how to install your own extension (named 'MyExt'):
#              perl -MWin32::ShellExt::MyExt -e " Win32::ShellExt::MyExt->install; "
#
sub install() {
	my $klass = shift;
	my $h = $klass->hkeys();
	my ($CLSID,$name,$package) = ( $h->{CLSID}, $h->{name}, $h->{package} );
	my $alias = "$package menu";

	my $hkeys = {
	"Classes/CLSID/$CLSID" => $name,
	"Classes/CLSID/$CLSID/InProcServer32/ThreadingModel" => "Apartment",
	"Classes/CLSID/$CLSID/InProcServer32/PerlPackage" => "$package",
	"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Shell Extensions/Approved/$CLSID" => $name
	};

	die "cannot open registry!" unless(defined($Registry));

	$Registry->Delimiter("/");

	$Registry->{"Classes/CLSID"}->CreateKey("$CLSID")->CreateKey("InProcServer32");
	$Registry->{"Classes/*/shellex/ContextMenuHandlers"}->CreateKey("$alias");
	#$Registry->{"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Shell Extensions/Approved"}->CreateKey("$CLSID");

	# FIXME hard-coded location for the perlext DLL.
#	$Registry->{"Classes/CLSID/$CLSID/InProcServer32"}->{""} = "D:\\build\\perl-win32-shellext\\perlshellext.dll";
	$Registry->{"Classes/CLSID/$CLSID/InProcServer32"}->{""} = "$Config{installbin}\\perlshellext.dll";

	$Registry->{"Classes/*/shellex/ContextMenuHandlers/$alias"}->{""} = $CLSID;

	&Win32::ShellExt::create_hkeys($hkeys);
	exit 0;
}

sub uninstall() {
	my $klass = shift;
	my $h = $klass->hkeys();
	my ($CLSID,$package) = ( $h->{CLSID}, $h->{package} );
	my $alias = "$package menu";

	die "cannot open registry!" unless(defined($Registry));	

	my @hkeys = reverse ( # order is important, we must destroy subkeys first.
	"Classes/CLSID/$CLSID/InProcServer32/",
	"Classes/CLSID/$CLSID/",
	"Classes/*/shellex/ContextMenuHandlers/$alias/",
	"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Shell Extensions/Approved/$CLSID"
	);
	&Win32::ShellExt::remove_hkeys(@hkeys);
	exit 0;
}

1;
__END__

=head1 NAME

Win32::ShellExt - Perl module for implementing context menu extensions of the Windows Explorer

=head1 SYNOPSIS

  # Sample usage of that module:
  package Win32::ShellExt::CopyPath;

  use strict;
  use Win32::ShellExt;
  use Win32::Clipboard;

  $Win32::ShellExt::CopyPath::VERSION='0.1';
  $Win32::ShellExt::CopyPath::TEXT="Copy path to clipboard";
  @Win32::ShellExt::CopyPath::ISA=qw(Win32::ShellExt);

  sub query_context_menu() {
    "Win32::ShellExt::CopyPath";
  }

  sub action() {
	my $self = shift;
	my $CLIP = Win32::Clipboard();
	$CLIP->Set(join '\n',@_);
	1;
  }

  sub hkeys() {
	my $h = {
	"CLSID" => "{E06853EF-4421-409C-BCFE-B2A048536F67}",
	"name"  => "copy path shell Extension",
	"alias" => "copy_path_menu",
	"package" => "Win32::ShellExt::CopyPath"
	};
	$h;
  }

  1;

=head1 DESCRIPTION

This module is never used directly. You always subclass it into your own package,
then do a one-time invocation of the install() method on your package (to install
the needed registry keys). Then you should have a new entry in the contextual menu
of the Windows explorer (the files for which this menu entry appears depend on the
filtering you do in the query_context_menu method), and your action() method gets
called upon clicking the corresponding menu command in the Explorer.

Blah blah blah.

=head2 EXPORT

None by default. None needed.

=head1 AUTHOR

Jean-Baptiste Nivoit E<lt>jbnivoit@hotmail.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
