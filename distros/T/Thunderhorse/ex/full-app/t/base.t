use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;
use FullApp;

my $app = FullApp->new(path => '.', initial_config => 'conf');

subtest 'should show welcome page' => sub {
	http $app, GET '/';
	http_status_is 200;
	http_header_is 'content-type', 'text/html; charset=utf-8';
	like http->text, qr{\Qappears to be operational\E}, 'body ok';
};

done_testing;

