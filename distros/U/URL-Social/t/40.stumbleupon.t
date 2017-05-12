use Test::More;

use FindBin;
use URL::Social;

my $url = ( $ENV{HARNESS_ACTIVE} ) ? 'file://' . $FindBin::Bin . '/data/stumbleupon_dagbladet.json' : 'http://www.dagbladet.no/';

my $url = URL::Social->new(
    url => $url,
);

ok( $url->stumbleupon->view_count >= 410, 'view_count' );

done_testing;
