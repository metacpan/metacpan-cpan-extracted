# -*- cperl -*-
# Win32/ShellExt/ColumnHandler.pm
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::ColumnProvider;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt;
$Win32::ShellExt::ColumnProvider::VERSION = '0.1';
@Win32::ShellExt::ColumnProvider::ISA = qw(Win32::ShellExt);

use Config; # to locate where the DLL is installed.
use Win32::TieRegistry 0.23 ( Delimiter=>"/", ArrayValues=>1 );

use constant IID_IColumnProvider => "{E8025004-1C42-11d2-BE2C-00A0C9A83DA1}";

sub new() {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);
  return $self;
}

#
# should be overloaded to return a ref to a list of ref to hashes containing the following entries:
#            scid : unique identifier for column.
#            cChars : the default width of the column, in characters
#            wszTitle : the title of the column
#            wszDescription : full description of this column
#
sub get_column_info() {
  my $self = shift;
  undef;
}

#
# should be overloaded to return the column data for the specified item/column passed.
#
sub get_item_data() {
  my ($self,$ext,$path) = @_;
  undef;
}

#
# Here's how to install your own extension (named 'MyExt'):
#              perl -MWin32::ShellExt::MyExt -e " Win32::ShellExt::MyExt->install; "
#
sub install() {
	my $klass = shift;
	my $h = $klass->hkeys();
	my ($CLSID,$package) = ( $h->{CLSID}, $h->{package} );
	my $alias = "$package menu";

	my $hkeys = {
	"Classes/CLSID/$CLSID" => "",
	"Classes/CLSID/$CLSID/InProcServer32/ThreadingModel" => "Apartment",
	"Classes/CLSID/$CLSID/InProcServer32/PerlPackage" => "$package",
	"Classes/CLSID/$CLSID/InProcServer32/TypeOfExtension" => "ColumnProvider"
	};

	die "cannot open registry!" unless(defined($Registry));

	$Registry->Delimiter("/");

	$Registry->{"Classes/CLSID"}->CreateKey("$CLSID")->CreateKey("InProcServer32");
	$Registry->{"Classes/CLSID/$CLSID/InProcServer32"}->{""} = "$Config{installbin}\\perlshellext.dll";

	$Registry->{"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Extensions/Approved"}->CreateKey("$CLSID");
	$Registry->{"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Extensions/Approved/$CLSID"}->{""} = "$package ColumnProvider extension";

	$Registry->{"Classes/Folder/ShellEx/ColumnHandlers"}->CreateKey("$CLSID");
	$Registry->{"Classes/Folder/ShellEx/ColumnHandlers/$CLSID"}->{""} = "$package ColumnProvider extension";

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
	"Classes/Folder/ShellEx/ColumnProviders/$CLSID",
	"LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Extensions/Approved/$CLSID"
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
  package Win32::ShellExt::ColumnProvider::Txt;

  use strict;
  use Win32::ShellExt::ColumnProvider;

  $Win32::ShellExt::ColumnProvider::Txt::VERSION='0.1';
  @Win32::ShellExt::ColumnProvider::Txt::ISA=qw(Win32::ShellExt::ColumnProvider);

  sub get_info_tip() {
    my $self = shift;
    "text file";
  }

  sub hkeys() {
	my $h = {
	"CLSID" => "{7952ADC6-C81A-4A95-8605-732F97535CA7}",
	"extension" => "txt",
	"package" => "Win32::ShellExt::ColumnProvider::Txt"
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

As usual, the methods get_column_info & get_item_data map to the 
methods GetColumnInfo & GetItemData of the IColumnProvider interface (in <shlobj.h>).

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
