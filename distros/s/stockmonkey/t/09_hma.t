
use Test;
use strict;

use Math::Business::HMA;

my $N    = 14;
my $Dp   = 250;
my @data = @{do "rand.data" or die $!}[0 .. $N+$Dp];
my $hma  = Math::Business::HMA->new(14);

my $min =  0;
my $max = 15;

plan tests => 1*@data;

my $ok = 1;
my @lt;
my @std;
for my $data (@data) {
    $hma->insert($data);

    if( defined( my $h = $hma->query ) ) {
        if( $h >= $min and $h <= $max ) {
            ok(1);

        } else {
            open DUMP, ">dump.txt" or die $!;
            print DUMP "@data";
            close DUMP;
            die " [false]  $h >= $min and $h <= $max \n";
            ok(0);
        }
        $ok = 0;

    } else {
        ok($ok);
    }
}
