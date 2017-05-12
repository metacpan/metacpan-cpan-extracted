use Test::More;

use FindBin;
use URL::Social;

my $url = ( $ENV{HARNESS_ACTIVE} ) ? 'file://' . $FindBin::Bin . '/data/linkedin_dagbladet.json' : 'http://www.dagbladet.no/';

my $url = URL::Social->new(
    url => $url,
);

ok( $url->linkedin->share_count >= 158, 'share_count' );

done_testing;
