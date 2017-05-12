use strict;
use warnings;

use if $^O eq 'MSWin32', 'Test::More' => skip_all => 'Forking may be problematic on Windows';

use Test::More;
use Test::Needs { Mojolicious => '6.0' };
use Test::TCP;
use HTTP::Tiny;
use HTTP::Request;
use LWP::UserAgent;
use Mojolicious::Lite;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Module::Runtime 'use_module';
use WWW::OAuth::Util 'oauth_request';

my $server = Test::TCP->new(code => sub {
	my $port = shift;
	my $guard = Mojo::IOLoop->timer(5 => sub { Mojo::IOLoop->stop });
	
	app->log->level('warn');
	
	get '/' => sub {
		my $c = shift;
		$c->render(text => 'foo');
	};
	
	my $daemon = Mojo::Server::Daemon->new(listen => ["http://127.0.0.1:$port"], app => app);
	$daemon->run;
	exit;
});

my $port = $server->port;

my $req = oauth_request({method => 'GET', url => "http://127.0.0.1:$port"});
my $res = $req->request_with(HTTP::Tiny->new);
ok $res->{success}, 'request succeeded';
is $res->{content}, 'foo', 'got response';

my $http_req = oauth_request(HTTP::Request->new(GET => "http://127.0.0.1:$port"));
my $http_res = $http_req->request_with(LWP::UserAgent->new);
ok $http_res->is_success, 'request succeeded';
is $http_res->content, 'foo', 'got response';

my $ua = Mojo::UserAgent->new;
my $tx = $ua->build_tx(GET => "http://127.0.0.1:$port");
my $mojo_req = oauth_request($tx->req);
$tx = $mojo_req->request_with($ua);
ok $tx->success, 'request succeeded';
is $tx->res->body, 'foo', 'got response';

undef $server;

done_testing;
