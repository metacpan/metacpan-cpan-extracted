# -*- perl -*-

# t/001_load.t - check module loading and create testing directory
use Test::More tests => 9;
BEGIN { use_ok( 'WWW::PDAScraper'); }

require_ok( 'URI::URL' );
require_ok( 'HTML::TreeBuilder' );
require_ok( 'HTML::Template' );
require_ok( 'Carp' );
require_ok( 'LWP::UserAgent' );
my $object = WWW::PDAScraper->new ();
isa_ok ($object, 'WWW::PDAScraper');
@methods = qw( scrape proxy download_location );
can_ok($object, @methods);
require_ok( 'WWW::PDAScraper::YahooMovies');