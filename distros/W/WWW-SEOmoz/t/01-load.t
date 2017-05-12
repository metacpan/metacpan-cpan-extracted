use Test::More tests => 4;

BEGIN { use_ok( 'WWW::SEOmoz' ); }
require_ok( 'WWW::SEOmoz' );

BEGIN { use_ok( 'WWW::SEOmoz::URLMetrics' ); }
require_ok( 'WWW::SEOmoz::URLMetrics' );
