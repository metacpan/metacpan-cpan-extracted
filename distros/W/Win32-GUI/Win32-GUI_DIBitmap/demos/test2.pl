#!perl -w
use strict;
use warnings;

#
# Test standalone :  Load and save in different format
#
# Functions Test :
#    - GetVersion
#    - GetCopyright
#    - newFromFile
#    - SaveToFile
#

use FindBin();
use File::Path;
use Win32::GUI::DIBitmap;

print Win32::GUI::DIBitmap::GetVersion(), "\n";
print Win32::GUI::DIBitmap::GetCopyright(), "\n";


my $dir_in = $FindBin::Bin;
print "Scanning $dir_in\n";

chdir $dir_in;
opendir (my $dh, '.') or die "error opendir";
my @Fichier = grep { -f $_ } readdir ($dh);
closedir ($dh);
print "Found files: @Fichier\n";

my $dir_out = "$dir_in/test2_dir";
print "Writing to $dir_out\n";
mkpath($dir_out);

my $i = 0;

foreach my $fichier (@Fichier) {
    $i ++;

    my $dib = Win32::GUI::DIBitmap->newFromFile ($fichier);
    if (defined $dib) {
        my $f = "$dir_out/$i.bmp";
		print "$fichier -> $f\n";
        $dib->SaveToFile($f);
        undef $dib;
    }
}

print "Press any key\n";
<>;

rmtree($dir_out);
