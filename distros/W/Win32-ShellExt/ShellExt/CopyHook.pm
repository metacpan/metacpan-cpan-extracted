# -*- cperl -*-
# Win32/ShellExt/CopyHook.pm
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::CopyHook;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt;
$Win32::ShellExt::CopyHook::VERSION = '0.1';
@Win32::ShellExt::CopyHook::ISA = qw(Win32::ShellExt);

use Config; # to locate where the DLL is installed.
use Win32::TieRegistry 0.23 ( Delimiter=>"/", ArrayValues=>1 );

use constant IID_ICopyHook => "{00021500-0000-0000-C000-000000000046}";

sub new() {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);
  return $self;
}

sub copycb() {
  my $self = shift;
  # @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

  return IDYES();
}

sub install() {
	my $klass = shift;
	my $h = $klass->hkeys();
	my ($CLSID,$package) = ( $h->{CLSID}, $h->{package} );

	my $hkeys = {
	"Classes/CLSID/$CLSID" => "",
	"Classes/CLSID/$CLSID/InProcServer32/ThreadingModel" => "Apartment",
	"Classes/CLSID/$CLSID/InProcServer32/PerlPackage" => "$package",
	"Classes/CLSID/$CLSID/InProcServer32/TypeOfExtension" => "CopyHook"
	};

	die "cannot open registry!" unless(defined($Registry));

	$Registry->Delimiter("/");

	$Registry->{"Classes/CLSID"}->CreateKey("$CLSID")->CreateKey("InProcServer32");
	$Registry->{"Classes/CLSID/$CLSID/InProcServer32"}->{""} = "$Config{installbin}\\perlshellext.dll";

	$Registry->{"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Extensions/Approved"}->CreateKey("$CLSID");
	$Registry->{"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Extensions/Approved/$CLSID"}->{""} = "$package CopyHook extension";

	$Registry->{"Classes"}->CreateKey("Directory")->CreateKey("ShellEx")->CreateKey("CopyHookHandlers")->CreateKey($package);
	$Registry->{"Classes/Directory/ShellEx/CopyHookHandlers/$package"}->{""} = $CLSID; # this might overwrite any other ICopyHook handler present before...

	&Win32::ShellExt::create_hkeys($hkeys);
	exit 0;
}

sub uninstall() {
	my $klass = shift;
	my $h = $klass->hkeys();
	my ($CLSID,$package) = ( $h->{CLSID}, $h->{package} );

	die "cannot open registry!" unless(defined($Registry));	

	my @hkeys = reverse ( # order is important, we must destroy subkeys first.
	"Classes/CLSID/$CLSID/InProcServer32/",
	"Classes/CLSID/$CLSID/",
	"Classes/Directory/ShellEx/CopyHookHandlers/$package",
	"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Extensions/Approved/$CLSID"
	);
	&Win32::ShellExt::remove_hkeys(@hkeys);
	exit 0;
}

# the following sub was copied verbatim from Compress::Zlib's Zlib.pm
#sub AUTOLOAD {
#    my($constname);
#    no strict;
#    ($constname = $AUTOLOAD) =~ s/.*:://;
#    return if($constname eq "bootstrap");
#    my ($error, $val) = constant($constname);
#    Carp::croak $error if $error;
#    no strict 'refs';
#    *{$AUTOLOAD} = sub { $val };
#    goto &{$AUTOLOAD};
#}

#bootstrap Win32::ShellExt::CopyHook $Win32::ShellExt::CopyHook::VERSION;

1;
__END__

=head1 NAME

Win32::ShellExt - Perl module for implementing context menu extensions of the Windows Explorer

=head1 SYNOPSIS

  # Sample usage of that module:
  package Win32::ShellExt::CopyHook::Txt;

  use strict;
  use Win32::ShellExt::CopyHook;

  $Win32::ShellExt::CopyHook::Txt::VERSION='0.1';
  @Win32::ShellExt::CopyHook::Txt::ISA=qw(Win32::ShellExt::CopyHook);

  sub get_info_tip() {
    my $self = shift;
    "text file";
  }

  sub hkeys() {
	my $h = {
	"CLSID" => "{7952ADC6-C81A-4A95-8605-732F97535CA7}",
	"extension" => "txt",
	"package" => "Win32::ShellExt::CopyHook::Txt"
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

=head2 EXPORT

None by default. None needed.

=head1 AUTHOR

Jean-Baptiste Nivoit E<lt>jbnivoit@hotmail.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
