use Test::More tests => 4;


BEGIN { use_ok( 'WWW::Trello::Lite' ); }
require_ok( 'WWW::Trello::Lite' );


my $request = WWW::Trello::Lite->new(
	key   => 'invalidkey',
	token => 'invalidtoken',
);
my $response = $request->get( 'lists/invalidlist' );

is( $response->failed, '', 'Verified connection to Trello' );
is( $response->response->content, "invalid key\n", 'Reported invalid board' );
