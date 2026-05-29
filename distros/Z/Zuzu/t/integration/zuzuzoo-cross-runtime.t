use Test2::V0;

use Config;
use File::Spec;
use File::Temp qw( tempfile tempdir );
use IPC::Run qw( run );
use IO::Socket::INET;
use Socket qw( SOL_SOCKET SO_REUSEADDR );

my $repo_root = File::Spec->rel2abs( File::Spec->curdir );

sub executable {
	my ( @parts ) = @_;
	my $path = File::Spec->catfile( $repo_root, @parts );
	return -x $path ? $path : undef;
}

sub command_available {
	my ( $command ) = @_;
	for my $dir ( File::Spec->path ) {
		my $path = File::Spec->catfile( $dir, $command );
		return 1 if -x $path;
	}
	return 0;
}

my @runtimes = (
	{
		name => 'Perl',
		cmd  => [ executable('bin', 'zuzu.pl') ],
	},
	{
		name => 'Rust',
		cmd  => [
			$ENV{ZUZU_RUST_BIN}
				// executable( qw( extras zuzu-rust target debug zuzu-rust ) )
				// executable( qw( extras zuzu-rust target release zuzu-rust ) )
		],
	},
	{
		name => 'JS/Node',
		cmd  => do {
			my $js_bin = $ENV{ZUZU_JS_BIN}
				// File::Spec->catfile( $repo_root, qw( extras zuzu-js bin zuzu-js ) );
			command_available('node') && -f $js_bin
				? [ 'node', $js_bin ]
				: undef;
		},
	},
);

sub run_zuzu {
	my ( $runtime, @args ) = @_;
	my @cmd = (
		@{ $runtime->{cmd} },
		'-Istdlib/modules',
		'-Istdlib/test-modules',
		@args,
	);
	my ( $stdout, $stderr ) = ( '', '' );
	run \@cmd, '<', \undef, '>', \$stdout, '2>', \$stderr;
	return {
		exit   => $? >> 8,
		stdout => $stdout,
		stderr => $stderr,
		cmd    => \@cmd,
	};
}

sub tap_passed {
	my ( $result ) = @_;
	return 0 if $result->{exit} != 0;
	return 0 if $result->{stdout} =~ /^\s*not ok\b/m;
	return $result->{stdout} =~ /^1\.\.\d+\s*$/m ? 1 : 0;
}

sub command_text {
	my ( $result ) = @_;
	return join ' ', @{ $result->{cmd} };
}

my @zuzuzoo_tests = qw(
	stdlib/tests/std/zuzuzoo/paths.zzs
	stdlib/tests/std/zuzuzoo/install-windows.zzs
	stdlib/tests/std/zuzuzoo/metadata.zzs
	stdlib/tests/std/zuzuzoo/queries.zzs
	stdlib/tests/std/zuzuzoo/verify.zzs
	stdlib/tests/std/zuzuzoo/source.zzs
);

my ( $import_fh, $import_script ) = tempfile(
	'zuzuzoo-import-XXXXXX',
	SUFFIX => '.zzs',
	TMPDIR => 1,
);
print {$import_fh} <<'ZZS';
from test/more import *;
from std/zuzuzoo import *;

ok( 1, "std/zuzuzoo imports" );
done_testing();
ZZS
close $import_fh;

for my $runtime ( @runtimes ) {
	if ( !defined $runtime->{cmd} || !defined $runtime->{cmd}[0] ) {
		SKIP: {
			skip $runtime->{name} . ' binary is unavailable', 1 + @zuzuzoo_tests;
		}
		next;
	}

	my $import = run_zuzu( $runtime, $import_script );
	ok tap_passed($import),
		"$runtime->{name} imports std/zuzuzoo"
		or diag command_text($import), $import->{stdout}, $import->{stderr};

	for my $test ( @zuzuzoo_tests ) {
		my $result = run_zuzu( $runtime, $test );
		ok tap_passed($result),
			"$runtime->{name} $test"
			or diag command_text($result), $result->{stdout}, $result->{stderr};
	}
}

sub start_redirect_server {
	my $listen = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Proto     => 'tcp',
		Listen    => 5,
		ReuseAddr => 1,
	) or return;
	setsockopt( $listen, SOL_SOCKET, SO_REUSEADDR, 1 );
	my $port = $listen->sockport;
	my $pid = fork();
	die "fork failed: $!" if !defined $pid;
	if ( $pid == 0 ) {
		local $SIG{TERM} = sub { exit 0 };
		while ( my $client = $listen->accept ) {
			my $line = <$client> // '';
			$line =~ s/[\r\n]+\z//;
			while ( my $header = <$client> ) {
				last if $header =~ /^\r?\n\z/;
			}
			my ( undef, $path ) = split /\s+/, $line, 3;
			if ( defined $path && $path eq '/redirect' ) {
				print {$client} "HTTP/1.1 302 Found\r\n";
				print {$client} "Location: /final\r\n";
				print {$client} "Content-Length: 0\r\n";
				print {$client} "Connection: close\r\n\r\n";
			}
			else {
				my $body = "redirect-ok\n";
				print {$client} "HTTP/1.1 200 OK\r\n";
				print {$client} "Content-Type: text/plain\r\n";
				print {$client} "Content-Length: " . length($body) . "\r\n";
				print {$client} "Connection: close\r\n\r\n";
				print {$client} $body;
			}
			close $client;
		}
		exit 0;
	}
	return ( $pid, "http://127.0.0.1:$port" );
}

my ( $http_fh, $http_script ) = tempfile(
	'zuzuzoo-http-redirect-XXXXXX',
	SUFFIX => '.zzs',
	TMPDIR => 1,
);
print {$http_fh} <<'ZZS';
from test/more import *;
from std/io import Path;
from std/net/http import UserAgent;

function __main__ ( argv ) {
	let base := argv[0];
	let dest := new Path(argv[1]);
	let ua := new UserAgent( max_redirect: 3 );
	let req := ua.build_request( "GET", base _ "/redirect" );
	req.download_to( dest.to_String() );
	let resp := ua.send(req);
	is( "" _ resp.status(), "200", "redirect response status" );
	is( resp.url(), base _ "/final", "response keeps effective URL" );
	is( dest.slurp_utf8(), "redirect-ok\n", "download_to stores redirected body" );
	done_testing();
}
ZZS
close $http_fh;

my ( $server_pid, $base_url ) = start_redirect_server();
if ( !$server_pid ) {
	SKIP: {
		skip 'local sockets unavailable for redirect fixture', scalar @runtimes;
	}
}
else {
	my $tmp = tempdir( CLEANUP => 1 );
	for my $runtime ( @runtimes ) {
		if ( !defined $runtime->{cmd} || !defined $runtime->{cmd}[0] ) {
			SKIP: {
				skip $runtime->{name} . ' binary is unavailable', 1;
			}
			next;
		}
		if ( $runtime->{name} eq 'JS/Node' && !command_available('curl') ) {
			SKIP: {
				skip 'curl is unavailable for JS/Node synchronous HTTP transport', 1;
			}
			next;
		}
		my $download = File::Spec->catfile(
			$tmp,
			lc( $runtime->{name} =~ s{[^A-Za-z0-9]+}{-}gr ) . '.txt',
		);
		my $result = run_zuzu( $runtime, $http_script, $base_url, $download );
		ok tap_passed($result),
			"$runtime->{name} std/net/http redirect download_to"
			or diag command_text($result), $result->{stdout}, $result->{stderr};
	}
	kill 'TERM', $server_pid;
	waitpid( $server_pid, 0 );
}

done_testing;
