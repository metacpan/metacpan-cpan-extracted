use Test2::V0;

use File::Spec;
use File::Temp qw( tempfile );
use IO::Socket::INET;
use IPC::Run qw( run );
use TAP::Parser;

use Zuzu::Parser;
use Zuzu::Runtime;

eval {
	require IO::Socket::SSL;
	IO::Socket::SSL->import( qw(
		SSL_VERIFY_FAIL_IF_NO_PEER_CERT
		SSL_VERIFY_PEER
	) );
	1;
} or plan skip_all => 'IO::Socket::SSL is required for mTLS integration tests';

my $repo_root = File::Spec->rel2abs( File::Spec->curdir );
my $fixture_dir = File::Spec->catdir(
	$repo_root,
	qw( t fixtures secure phase12-mtls ),
);
my $ca_pem = _slurp( File::Spec->catfile( $fixture_dir, 'ca.pem' ) );
my $client_pem = _slurp( File::Spec->catfile( $fixture_dir, 'client.pem' ) );
my $client_key = _slurp( File::Spec->catfile( $fixture_dir, 'client.key' ) );

my $server = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Proto => 'tcp',
	Listen => 10,
	ReuseAddr => 1,
);
if ( not $server ) {
	plan skip_all => "local sockets are unavailable: $!"
		if "$!" =~ /Operation not permitted/i;
	die "Could not start local mTLS server: $!";
}
my $port = $server->sockport;

my $pid = fork();
defined $pid or die "fork failed: $!";
if ( $pid == 0 ) {
	local $SIG{TERM} = sub { exit 0 };
	for ( 1 .. 100 ) {
		my $client = $server->accept();
		next if not $client;
		my $tls_client = IO::Socket::SSL->start_SSL(
			$client,
			SSL_server => 1,
			SSL_cert_file => File::Spec->catfile( $fixture_dir, 'server.pem' ),
			SSL_key_file => File::Spec->catfile( $fixture_dir, 'server.key' ),
			SSL_ca_file => File::Spec->catfile( $fixture_dir, 'ca.pem' ),
			SSL_verify_mode => SSL_VERIFY_PEER()
				| SSL_VERIFY_FAIL_IF_NO_PEER_CERT(),
		);
		next if not $tls_client;
		$client = $tls_client;
		my $line = <$client>;
		next if not defined $line;
		while ( my $header = <$client> ) {
			last if $header =~ /^\r?\n\z/;
		}
		my $body = "mtls-ok\n";
		print {$client} "HTTP/1.1 200 OK\r\n";
		print {$client} "Content-Type: text/plain\r\n";
		print {$client} "Content-Length: " . length($body) . "\r\n";
		print {$client} "Connection: close\r\n\r\n";
		print {$client} $body;
		close $client;
	}
	exit 0;
}

my $script = _script(
	"https://localhost:$port/mtls",
	$ca_pem,
	$client_pem,
	$client_key,
);

subtest 'Perl std/net/http mTLS' => sub {
	my $tap = '';
	my $stderr = '';
	my $parser = Zuzu::Parser->new;
	my $ast = $parser->parse( $script, 'phase12-mtls.zzs' );
	my $runtime = Zuzu::Runtime->new(
		lib => [
			File::Spec->catdir( $repo_root, 'stdlib', 'test-modules' ),
			File::Spec->catdir( $repo_root, 'stdlib', 'modules' ),
		],
	);
	my $ok = eval {
		local *STDOUT;
		local *STDERR;
		open STDOUT, '>:encoding(UTF-8)', \$tap or die $!;
		open STDERR, '>:encoding(UTF-8)', \$stderr or die $!;
		$runtime->evaluate($ast);
		1;
	};
	ok $ok, 'executed Perl mTLS script' or diag $@;
	diag $tap if not $ok;
	diag $stderr if length $stderr;
	_assert_tap($tap);
};

my ( $fh, $path ) = tempfile( 'zuzu-phase12-mtls-XXXXXX', SUFFIX => '.zzs' );
print {$fh} $script;
close $fh;

my @cli = (
	[
		'JS/Node std/net/http mTLS',
		_runtime_cmd(
			$ENV{ZUZU_JS_BIN},
			File::Spec->catfile( $repo_root, qw( extras zuzu-js bin zuzu-js ) ),
			sub { [ 'node', $_[0], $path ] },
		),
	],
	[
		'Rust std/net/http mTLS',
		_runtime_cmd(
			$ENV{ZUZU_RUST_BIN},
			File::Spec->catfile(
				$repo_root,
				qw( extras zuzu-rust target debug zuzu-rust ),
			),
			sub { [ $_[0], $path ] },
		),
	],
);

for my $case ( @cli ) {
	my ( $name, $cmd ) = @{ $case };
	subtest $name => sub {
		skip_all "$name runtime is not available"
			if not defined $cmd;
		my $stdout = '';
		my $stderr = '';
		run $cmd, '<', \undef, '>', \$stdout, '2>', \$stderr;
		if ( not is $?, 0, 'runtime exits successfully' ) {
			diag $stdout if length $stdout;
			diag $stderr if length $stderr;
		}
		_assert_tap($stdout);
	};
}

kill 'TERM', $pid;
waitpid( $pid, 0 );
unlink $path;

done_testing;

sub _runtime_cmd {
	my ( $env_path, $default_path, $builder ) = @_;
	my $runtime = defined $env_path && $env_path ne ''
		? $env_path
		: $default_path;
	return undef if not defined $runtime or not -f $runtime;
	return $builder->($runtime);
}

sub _script {
	my ( $url, $ca, $cert, $key ) = @_;

	return <<"ZZS";
from std/net/http import UserAgent;
from std/secure import Certificate, TlsIdentity;
from test/more import *;

let ca_pem := @{[ _zuzu_string($ca) ]};
let client_pem := @{[ _zuzu_string($cert) ]};
let client_key := @{[ _zuzu_string($key) ]};
let url := @{[ _zuzu_string($url) ]};

let ca := Certificate.parse(ca_pem);
let identity := TlsIdentity.from_pem(client_pem, client_key);

let ua := new UserAgent( tls_ca: ca, tls_identity: identity, timeout: 5 );
let resp := await { ua.get_async(url) };
if ( not resp.success() ) {
	diag( resp.reason() );
}

is( 0 + resp.status(), 200, "user-agent TLS identity succeeds" );
is( resp.content(), "mtls-ok\\n", "mTLS response body is returned" );

let request_ua := new UserAgent( tls_ca: ca, timeout: 5 );
let request := request_ua.build_request( "GET", url );
request.tls_identity(identity);
let request_resp := await { request.send_async(request_ua) };
is( 0 + request_resp.status(), 200, "request TLS identity override succeeds" );

let disabled := ua.build_request( "GET", url );
disabled.tls_identity(null);
let disabled_resp := await { ua.send_async(disabled) };
ok( not disabled_resp.success(), "request null TLS identity disables UA identity" );

let insecure := new UserAgent(
	tls_identity: identity,
	tls_verify: false,
	timeout: 5,
);
let insecure_resp := await { insecure.get_async(url) };
is( 0 + insecure_resp.status(), 200, "tls_verify false permits test CA" );

if ( __system__{runtime} eq "zuzu-rust" ) {
	like(
		exception( function () {
			new UserAgent( tls_ciphers: "HIGH" ).get(url);
		} ),
		/not supported/,
		"Rust rejects unsupported tls_ciphers clearly",
	);
}

done_testing();
ZZS
}

sub _assert_tap {
	my ( $tap ) = @_;

	my $parser = TAP::Parser->new( { source => \$tap } );
	my $tests = 0;
	while ( my $result = $parser->next ) {
		if ( $result->is_test ) {
			$tests++;
			ok $result->is_ok, $result->description || "test $tests";
		}
		elsif ( $result->is_bailout ) {
			fail 'ztest bailed out';
			diag $result->as_string;
		}
	}
	ok $tests > 0, 'ztest produced TAP tests';
	ok $parser->is_good_plan, 'ztest TAP plan is valid';
	ok !$parser->has_problems, 'ztest TAP stream has no parser problems';
}

sub _slurp {
	my ( $path ) = @_;

	open my $fh, '<:encoding(UTF-8)', $path or die "open $path: $!";
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

sub _zuzu_string {
	my ( $text ) = @_;

	$text =~ s/\\/\\\\/g;
	$text =~ s/"/\\"/g;
	$text =~ s/\n/\\n/g;
	return qq("$text");
}

sub _command_available {
	my ( $command ) = @_;

	return -x $command if File::Spec->file_name_is_absolute($command);
	for my $dir ( File::Spec->path ) {
		my $path = File::Spec->catfile( $dir, $command );
		return 1 if -x $path;
	}
	return 0;
}
