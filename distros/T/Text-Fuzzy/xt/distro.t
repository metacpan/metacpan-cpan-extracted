use warnings;
use strict;
use Test::More;
use FindBin;

# Check that OPTIMIZE is not defined in Makefile.PL.

my $file = "$FindBin::Bin/../Makefile.PL";
open my $in, "<", $file or die $!;
while (<$in>) {
    if (/-Wall/) {
	like ($_, qr/^\s*#/, "Commented out -Wall in Makefile.PL");
    }
}
close $in or die $!;

done_testing ();
