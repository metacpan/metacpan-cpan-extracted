use Test::More;

use FindBin;
use URL::Social;

my $url = ( $ENV{HARNESS_ACTIVE} ) ? 'file://' . $FindBin::Bin . '/data/twitter_e24.json' : 'http://e24.no/naeringsliv/innovasjon-norge-deler-ut-milliarder-har-ingen-konkurs-oversikt/20337046';

my $social = URL::Social->new(
    url => $url,
);

ok( $social->twitter->share_count >= 47, 'share_count' );

done_testing;
