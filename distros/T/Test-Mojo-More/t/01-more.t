use Test::More;
eval 'use Test::More::Color';
use Mojolicious::Lite;

if ( app->can('secrets') ) {
	app->secrets(['123', '456', '789']);
}
else {
	app->secret('1234567890');
}

get '/flash' => sub {
	my $c = shift;
	$c->flash( foo => 'bar', monkey => 'banana' );
	$c->render( text => 'flashes=foo:bar;mokey:banana' );
};

get '/cookie' => sub {
	my $c = shift;
	$c->cookie( bar => 'foo' );
	$c->cookie( banana => 'monkey' );
	$c->render( text => 'cookies=bar:foo;banana:monkey' );
};

use_ok 'Test::Mojo::More';
my $t = new_ok 'Test::Mojo::More';

pass "Mojolicious $Mojolicious::VERSION, $Mojolicious::CODENAME";

subtest 'flash' => sub {
	$t->get_ok('/flash')->status_is('200')
		->flash_has('/foo')
		->flash_has('/monkey')
		->flash_hasnt('/error')
		->flash_is('/foo' => 'bar')
		->flash_is('/monkey' => 'banana');

	my $hash = $t->flash_hashref;
	is $hash->{foo}, 'bar', 'flash_hashref';
	is $hash->{monkey}, 'banana', 'flash_hashref';
};

subtest 'cookie' => sub {
	$t->get_ok('/cookie')->status_is('200')
		->cookie_has('bar')
		->cookie_has('banana')
		->cookie_hasnt('error')
		->cookie_is('bar' => 'foo')
		->cookie_isnt('bar' => 'fooo')
		->cookie_like('bar' => qr/oo/)
		->cookie_like('banana' => qr/nke/)
		->cookie_unlike('banana' => qr/not/);

	my $hash = $t->cookie_hashref;
	is $hash->{bar}, 'foo', 'cookie_hashref';
	is $hash->{banana}, 'monkey', 'cookie_hashref';

};


done_testing;
