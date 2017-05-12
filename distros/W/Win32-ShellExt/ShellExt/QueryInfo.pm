# -*- cperl -*-
# Win32/ShellExt/QueryInfo.pm
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::QueryInfo;

use 5.006;
use strict;
use warnings;
$Win32::ShellExt::QueryInfo::VERSION = '0.1';
@Win32::ShellExt::QueryInfo::ISA = qw(Win32::ShellExt);

use Config; # to locate where the DLL is installed.
use Win32::TieRegistry 0.23 ( Delimiter=>"/", ArrayValues=>1 );

use constant IID_IQueryInfo => "{00021500-0000-0000-C000-000000000046}";

sub new() {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);
  return $self;
}

# 'get_info_tip' is what subclasses should override.
sub get_info_tip() {
  my $self = shift;
  # @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

  # return the info string (returning an empty string will make the C++ code return an error code to the Explorer).
  "";
}

#
# Here's how to install your own extension (named 'MyExt'):
#              perl -MWin32::ShellExt::MyExt -e " Win32::ShellExt::MyExt->install; "
#
sub install() {
	my $klass = shift;
	my $h = $klass->hkeys();
	my ($CLSID,$ext,$package) = ( $h->{CLSID}, $h->{extension}, $h->{package} );
	my $alias = "$package menu";

	my $hkeys = {
	"Classes/CLSID/$CLSID" => "",
	"Classes/CLSID/$CLSID/InProcServer32/ThreadingModel" => "Apartment",
	"Classes/CLSID/$CLSID/InProcServer32/PerlPackage" => "$package",
	"Classes/CLSID/$CLSID/InProcServer32/TypeOfExtension" => "QueryInfo"
	};

	die "cannot open registry!" unless(defined($Registry));

	$Registry->Delimiter("/");

	$Registry->{"Classes/CLSID"}->CreateKey("$CLSID")->CreateKey("InProcServer32");
	$Registry->{"Classes/CLSID/$CLSID/InProcServer32"}->{""} = "$Config{installbin}\\perlshellext.dll";

	$Registry->{"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Extensions/Approved"}->CreateKey("$CLSID");
	$Registry->{"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Extensions/Approved/$CLSID"}->{""} = "$package QueryInfo extension";

	$Registry->{"Classes"}->CreateKey(".$ext")->CreateKey("ShellEx")->CreateKey(IID_IQueryInfo);
	$Registry->{"Classes/.$ext/ShellEx/". IID_IQueryInfo}->{""} = $CLSID; # this might overwrite any other IQueryInfo handler present before...

	create_hkeys($hkeys);
	exit 0;
}

sub uninstall() {
	my $klass = shift;
	my $h = $klass->hkeys();
	my ($CLSID,$ext,$package) = ( $h->{CLSID}, $h->{extension}, $h->{package} );
	my $alias = "$package menu";

	die "cannot open registry!" unless(defined($Registry));	

	my @hkeys = reverse ( # order is important, we must destroy subkeys first.
	"Classes/CLSID/$CLSID/InProcServer32/",
	"Classes/CLSID/$CLSID/",
	"Classes/.$ext/ShellEx/". IID_IQueryInfo,
	"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Extensions/Approved/$CLSID"
	);
	remove_hkeys(@hkeys);
	exit 0;
}

sub create_hkeys() {

	my $hkeys = shift;

	my $hkey;
	foreach $hkey (sort keys %$hkeys) {
	  print "adding $hkey => $hkeys->{$hkey}\n";
	  $Registry->{$hkey} = $hkeys->{$hkey};
	}

}

sub remove_hkeys() {
	my $hkey;

	$Registry->Delimiter("/");

	while ($hkey = pop @_) {
	  print "removing $hkey\n";
	  delete $Registry->{$hkey} or die $^E;
	}
}

1;
__END__

=head1 NAME

Win32::ShellExt - Perl module for implementing context menu extensions of the Windows Explorer

=head1 SYNOPSIS

  # Sample usage of that module:
  package Win32::ShellExt::QueryInfo::Txt;

  use strict;
  use Win32::ShellExt::QueryInfo;

  $Win32::ShellExt::QueryInfo::Txt::VERSION='0.1';
  @Win32::ShellExt::QueryInfo::Txt::ISA=qw(Win32::ShellExt::QueryInfo);

  sub get_info_tip() {
    my $self = shift;
    "text file";
  }

  sub hkeys() {
	my $h = {
	"CLSID" => "{7952ADC6-C81A-4A95-8605-732F97535CA7}",
	"extension" => "txt",
	"package" => "Win32::ShellExt::QueryInfo::Txt"
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

Note the additionnal hkey entry that modules deriving from Win32::ShellExt
don't have: 'extension' this is used to set up the registry entries to tell
explorer which kinds of files your extension works on.

=head2 EXPORT

None by default. None needed.

=head1 AUTHOR

Jean-Baptiste Nivoit E<lt>jbnivoit@hotmail.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
