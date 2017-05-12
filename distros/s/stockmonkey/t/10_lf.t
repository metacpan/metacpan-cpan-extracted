
use Test;
use strict;

use Math::Business::LaguerreFilter;

my $N   = 14;
my $Dp  = 250;
my @data = @{do "rand.data" or die $!}[0 .. $N*$Dp];
my $lag = Math::Business::LaguerreFilter->new(0.4);

my $min = my $max = $data[0];
for my $data (@data) {
    $min = $data if $data < $min;
    $max = $data if $data > $max;
}

plan tests => 1*@data
    + 2 # invocations
    ;

my $ok = 1;
for my $data (@data) {
    $lag->insert($data);

    if( defined( my $h = $lag->query ) ) {
        if( $h >= $min and $h <= $max ) {
            ok(1);

        } else {
            open DUMP, ">dump.txt" or die $!;
            print DUMP "@data";
            close DUMP;
            warn " [false]  $h >= $min and $h <= $max \n";
            ok(0);
        }
        $ok = 0;

    } else {
        ok($ok);
    }
}

my $rv = eval { my $lag = Math::Business::LaguerreFilter->new(0.2,9); 3 };
ok "$rv $@", "3 ";

my $rv = eval { my $lag = Math::Business::LaguerreFilter->new; 3 };
ok "$rv $@", "3 ";
