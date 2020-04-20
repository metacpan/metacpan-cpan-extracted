use Test::More tests => 5;


BEGIN { use_ok( 'WWW::Trello::Lite' ); }
require_ok( 'WWW::Trello::Lite' );


my $request = WWW::Trello::Lite->new(
	key   => 'invalidkey',
	token => 'invalidtoken',
);
my $response = $request->get( 'lists/invalidlist' );

ok( defined( $response ), 'Verified connection to Trello' );
ok( defined( $response->response ), 'Trello return code' );
like( $response->response->content(), qr/^invalid key\b/i, 'Reported invalid board' );
