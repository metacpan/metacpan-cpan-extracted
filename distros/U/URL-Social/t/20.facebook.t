use Test::More;

use FindBin;
use URL::Social;

my $url = ( $ENV{HARNESS_ACTIVE} ) ? 'file://' . $FindBin::Bin . '/data/facebook_e24.json' : 'http://e24.no/naeringsliv/innovasjon-norge-deler-ut-milliarder-har-ingen-konkurs-oversikt/20337046';

my $social = URL::Social->new(
    url => $url,
);

ok( $social->facebook->share_count   >= 173, 'share_count'   );
ok( $social->facebook->like_count    >= 213, 'like_count'    );
ok( $social->facebook->comment_count >= 149, 'comment_count' );
ok( $social->facebook->click_count   >=   0, 'click_count'   );
ok( $social->facebook->total_count   >= 535, 'total_count'   );

done_testing;
