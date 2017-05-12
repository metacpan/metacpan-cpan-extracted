

use Test;
use strict;
no warnings;

use Math::Business::ConnorRSI;

my $crsi = Math::Business::ConnorRSI->new(3,2,100);
my $data = do 'jpm-2013-10-02.txt' or die "problem loading test data: $!$@";

my @crsi_from_tradeingview_d_com = (
    ["2013/09/24", 10.7726],
    ["2013/09/25", 74.1468],
    ["2013/09/26", 64.6039],
    ["2013/09/27", 73.8535],
    ["2013/09/30", 26.7223],
    ["2013/10/01", 57.4290],
);

my @mb_crsi;

for my $row (@$data) {
    $crsi->insert($row->[-1]);
    my $v = $crsi->query;

    push @mb_crsi, [$row->[0], $v];
}

plan tests => 0+@crsi_from_tradeingview_d_com;

while( @crsi_from_tradeingview_d_com ) {
    my $tv_crsi = pop @crsi_from_tradeingview_d_com;
    my $mb_crsi = pop @mb_crsi;

    my $d = abs($tv_crsi->[1] - $mb_crsi->[1]);

    if( $d < 0.5 ) {
        ok( 1 );

    } else {
        ok("@$mb_crsi", "@$tv_crsi");
    }
}
