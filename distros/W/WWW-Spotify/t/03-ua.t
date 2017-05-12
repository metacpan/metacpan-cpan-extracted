use strict;
use warnings;

use Test::More;
use WWW::Mechanize ();
use WWW::Spotify   ();

my $ua = WWW::Mechanize->new( autocheck => 0 );
$ua->agent('foo');
my $spotify = WWW::Spotify->new( ua => $ua );

is( $spotify->ua->agent, 'foo', 'uses custom ua' );

done_testing();
