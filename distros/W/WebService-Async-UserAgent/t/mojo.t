use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
	eval {
		require Mojo::UserAgent;
		require Future::Mojo;
	} or do {
		plan skip_all => '"mojo" feature deps not found';
	}
}

use WebService::Async::UserAgent::MojoUA;

my $ua = new_ok('WebService::Async::UserAgent::MojoUA', [
]);

my $server_id = Mojo::IOLoop->server({ address => '127.0.0.1' } => sub {
	my ($loop, $stream) = @_;

	note "Have new connection";
	my $buffer = '';
	$stream->on(read => sub {
		my ($stream, $bytes) = @_;

		$buffer .= $bytes;

		note "Had line: $1" while $buffer =~ s/^(.+)\x0D\x0A//;
		if($buffer =~ s/^\x0D\x0A//) {
			note "Sending response";
			$stream->write(join "\x0D\x0A",
				"HTTP/1.1 200 OK",
				"Host: localhost",
				"Content-Length: 4",
				"Content-Type: text/plain",
				"",
				"test"
			);
		}
	});
});
my $port = Mojo::IOLoop->acceptor($server_id)->port;

is(exception {
	my ($resp) = $ua->get(
		'http://127.0.0.1:' . $port
	)->get;
	is($resp, 'test', 'body was correct');
}, undef, 'no exception on GET') or note explain $@;

done_testing;

