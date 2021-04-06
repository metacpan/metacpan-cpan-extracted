# Print all registered type library names
# Warn about different classids using the same type library name.

use strict;
use Win32::Registry;
use vars qw($HKEY_CLASSES_ROOT);

my %Version;
my ($hTypelib,$hClsid);
$HKEY_CLASSES_ROOT->Create('TypeLib',$hTypelib)
  or die "Cannot access HKEY_CLASSES_ROOT\\Typelib";
my $Clsids = [];
$hTypelib->GetKeys($Clsids);
foreach my $clsid (@$Clsids) {
    $hTypelib->Create($clsid,$hClsid);
    next unless $hClsid;
    my $Versions = [];
    $hClsid->GetKeys($Versions);
    foreach my $version (@$Versions) {
	my $value;
	next unless $hClsid->QueryValue($version,$value);
	printf "*** Typelib name \"$value\" multiply defined ***\n"
	  if defined $Version{$value};
	$Version{$value} = join(', ', @$Versions);;
    }
    $hClsid->Close;
}
$hTypelib->Close;

foreach my $TypeLib (sort keys %Version) {
    printf "%-60s %s\n", $TypeLib, $Version{$TypeLib};
}
