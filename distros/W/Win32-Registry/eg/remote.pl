# Read and display a remote registry entry
#
# Contributed by Michael Frederick
#
use Win32::Registry;
my ($node) = shift;
my ($hNode, $hKey, $SPLevel, %values);

$HKEY_LOCAL_MACHINE->Connect ($node, $hNode) or exit(1);
$hNode->Open ("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion", $hKey)
    or exit(1);
$hKey->GetValues (\%values);
$hKey->Close ();
$hNode->Close ();

foreach (keys (%values)) {
  print "Value $_, data = $values{$_}[2]\n";
}
