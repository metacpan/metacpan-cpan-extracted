use Test2::V0;

use File::Find qw( find );
use File::Spec;
use File::Temp qw( tempdir );
use IO::Socket::INET;
use JSON::PP qw( decode_json );
use Scalar::Util qw( blessed );
use Socket qw( SOL_SOCKET SO_REUSEADDR );

use Zuzu::Parser;
use Zuzu::Runtime;

sub module_ids_from_std_tree {
	my ( $root ) = @_;
	my @ids;

	find(
		sub {
			return if -d $_;
			return if $_ !~ /\.(?:zzm|zzs)\z/;
			my $rel = File::Spec->abs2rel( $File::Find::name, $root );
			$rel =~ s{\\}{/}g;
			$rel =~ s{\.(?:zzm|zzs)\z}{};
			push @ids, "std/$rel";
		},
		$root,
	);

	return [ sort @ids ];
}

sub module_ids_from_ztests {
	my ( $root ) = @_;
	my @ids;

	find(
		sub {
			return if -d $_;
			return if $_ !~ /\.zzs\z/;
			my $rel = File::Spec->abs2rel( $File::Find::name, $root );
			$rel =~ s{\\}{/}g;
			$rel =~ s{\.zzs\z}{};
			push @ids, "std/$rel";
		},
		$root,
	);

	return [ sort @ids ];
}

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $module_ids = module_ids_from_std_tree(
	File::Spec->catdir( $repo_root, 'stdlib', 'modules', 'std' ),
);
my $ztest_ids = module_ids_from_ztests(
	File::Spec->catdir( $repo_root, 'stdlib', 'tests', 'std' ),
);

my %has_ztest = map { $_ => 1 } @{$ztest_ids};
my @missing_contracts = grep { !$has_ztest{$_} } @{$module_ids};
is scalar @missing_contracts, 0,
	'every stdlib module has a native ztest contract owner';

my $parser = Zuzu::Parser->new;
for my $module_id ( @{$module_ids} ) {
	my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules', 'stdlib/test-modules' ] );
	my $ast = $parser->parse(
		"from $module_id import *;",
		"test3-import-$module_id.zzs",
	);
	ok( lives { $runtime->evaluate($ast) },
		"module import smoke: $module_id" );
}

my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules', 'stdlib/test-modules' ] );

my $tmp = tempdir( CLEANUP => 1 );
my $listen = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Proto => 'tcp',
	Listen => 5,
	ReuseAddr => 1,
) or die "Could not start local HTTP listener: $!";
setsockopt( $listen, SOL_SOCKET, SO_REUSEADDR, 1 );
my $port = $listen->sockport;

my $pid = fork();
defined $pid or die "fork failed: $!";
if ( $pid == 0 ) {
	local $SIG{TERM} = sub { exit 0 };
	while ( my $client = $listen->accept() ) {
		my $line = <$client>;
		$line //= '';
		$line =~ s/[\r\n]+\z//;
		while ( my $header = <$client> ) {
			last if $header =~ /^\r?\n\z/;
		}
		my ( undef, $path ) = split /\s+/, $line, 3;
		my $name = 'world';
		if ( defined $path and $path =~ /[?&]name=([^&]+)/ ) {
			$name = $1;
			$name =~ s/%20/ /g;
		}
		my $body = qq|{"ok":true,"greeting":"hello $name"}|;
		print {$client} "HTTP/1.1 200 OK\r\n";
		print {$client} "Content-Type: application/json\r\n";
		print {$client} "Content-Length: " . length($body) . "\r\n";
		print {$client} "Connection: close\r\n\r\n";
		print {$client} $body;
		close $client;
	}
	exit 0;
}

my $workflow_ast = $parser->parse(
	<<'SRC',
from std/data/json import JSON;
from std/io import Path;
from std/log import Log;
from std/net/http import UserAgent;

function run_workflow (url, name) {
	Log.configure( { level: "error", timestamps: 0, stderr_for_errors: 1 } );

	let ua := new UserAgent();
	let req := ua.build_request( "GET", url );
	req.query( { name: name } );
	let resp := ua.send(req);
	resp.expect_success();

	let json := new JSON( canonical: true );
	let path := Path.tempfile();
	let payload := resp.json();
	json.dump( path, payload );
	let loaded := json.load(path);
	if ( loaded{greeting} ne ( "hello " _ name ) ) {
		return 0;
	}
	return 1;
}
SRC
	'test3-workflow.zzs',
);

$runtime->evaluate($workflow_ast);

ok( lives {
	$runtime->call(
		'run_workflow',
		"http://127.0.0.1:$port/data",
		'zuzu',
	);
},
	'workflow output stores API payload from local server after file write' );

kill 'TERM', $pid;
waitpid( $pid, 0 );

my $property_ast = $parser->parse(
	<<'SRC',
from std/data/json import JSON;

function json_property_checks () {
	let codec := new JSON( canonical: true );
	let cases := [
		{ s: "zuzu", n: 7, ok: true, list: [ 1, 2, 3 ] },
		{ s: "tea time", n: 0, ok: false, list: [] },
	];

	for ( let c in cases ) {
		codec.decode( codec.encode(c) );
	}

	return 1;
}
SRC
	'test3-json-property.zzs',
);

$runtime->evaluate($property_ast);

ok( lives {
	$runtime->call('json_property_checks');
},
	'JSON property roundtrip preserves deterministic fixture set' );

done_testing;
