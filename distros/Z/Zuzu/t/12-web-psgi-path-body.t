use utf8;
use strict;
use warnings;

use Test2::V0;

use File::Spec;
use File::Temp qw( tempdir );
use HTTP::Request::Common qw( GET );
use Plack::Test;

use Zuzu::Web::PSGI;

sub write_file {
	my ( $path, $bytes ) = @_;

	open my $fh, '>:raw', $path
		or die "Could not create $path: $!";
	print {$fh} $bytes;
	close $fh;

	return $path;
}

sub write_script {
	my ( $dir, $name, $source ) = @_;

	my $path = File::Spec->catfile( $dir, $name );
	open my $fh, '>:encoding(UTF-8)', $path
		or die "Could not create $path: $!";
	print {$fh} $source;
	close $fh;

	return $path;
}

sub zuzu_string {
	my ( $text ) = @_;

	$text =~ s/\\/\\\\/g;
	$text =~ s/"/\\"/g;

	return qq{"$text"};
}

sub error_stream {
	my $log = '';
	open my $fh, '>', \$log
		or die "Could not open scalar error stream: $!";

	return ( $fh, \$log );
}

my $tmpdir = tempdir( CLEANUP => 1 );
my $text_path = write_file(
	File::Spec->catfile( $tmpdir, 'asset.txt' ),
	"static text\n",
);
my $custom_path = write_file(
	File::Spec->catfile( $tmpdir, 'asset.zuzu-static' ),
	"custom type\n",
);
my $unknown_path = write_file(
	File::Spec->catfile( $tmpdir, 'asset.zzzunknown' ),
	"unknown type\n",
);
my $missing_path = File::Spec->catfile( $tmpdir, 'missing.txt' );

{
	my $script = write_script(
		$tmpdir,
		'path-response.zzs',
		'from std/io import Path;

function __request__ ( env ) {
	let path := env.get( "path" );
	if ( path eq "/file" ) {
		return [ 203, {{}}, new Path(' . zuzu_string($text_path) . ') ];
	}
	if ( path eq "/explicit-type" ) {
		return [
			200,
			{ "Content-Type": "application/x-zuzu-test" },
			new Path(' . zuzu_string($custom_path) . '),
		];
	}
	if ( path eq "/unknown-type" ) {
		return [ 200, {{}}, new Path(' . zuzu_string($unknown_path) . ') ];
	}
	if ( path eq "/missing" ) {
		return [ 200, {{}}, new Path(' . zuzu_string($missing_path) . ') ];
	}
	if ( path eq "/directory" ) {
		return [ 200, {{}}, new Path(' . zuzu_string($tmpdir) . ') ];
	}
	return [ 404, { "Content-Type": "text/plain" }, [ "route missing\n" ] ];
}
',
	);
	my $app = Zuzu::Web::PSGI->app( script => $script );

	test_psgi app => $app, client => sub {
		my ( $cb ) = @_;

		my $res = $cb->( GET '/file' );
		is( $res->code, 203, 'Path body preserves app status for files' );
		is( $res->content, "static text\n", 'Path body serves file bytes' );
		is( $res->header('Content-Type'), 'text/plain', 'Path body infers type' );

		$res = $cb->( GET '/explicit-type' );
		is(
			$res->header('Content-Type'),
			'application/x-zuzu-test',
			'explicit Content-Type is preserved for Path body',
		);
		is( $res->content, "custom type\n", 'explicit type file body is served' );

		$res = $cb->( GET '/unknown-type' );
		is(
			$res->header('Content-Type'),
			'application/octet-stream',
			'unknown extension uses octet-stream',
		);

		$res = $cb->( GET '/missing' );
		is( $res->code, 404, 'missing Path body maps to 404' );
		is( $res->content, "Not Found\n", 'missing Path body has stable body' );

		$res = $cb->( GET '/directory' );
		is( $res->code, 403, 'directory Path body maps to 403' );
		is( $res->content, "Forbidden\n", 'directory Path body has stable body' );
	};
}

{
	my $script = write_script(
		$tmpdir,
		'path-inside-array.zzs',
		'from std/io import Path;

function __request__ ( env ) {
	return [
		200,
		{ "Content-Type": "text/plain" },
		[ new Path(' . zuzu_string($text_path) . ') ],
	];
}
',
	);
	my $app = Zuzu::Web::PSGI->app( script => $script );
	my ( $errors, $log_ref ) = error_stream();
	my $response = $app->({ 'psgi.errors' => $errors });

	is( $response->[0], 500, 'Path inside body array remains unsupported' );
	like(
		$$log_ref,
		qr/Unsupported Zuzu PSGI response body value/,
		'unsupported nested Path is logged',
	);
}

{
	my $script = write_script(
		$tmpdir,
		'compat-routes.zzs',
		'from std/io import Path;

function __request__ ( env ) {
	let path := env.get( "path" );
	if ( path eq "/text" ) {
		return [ 200, { "Content-Type": "text/plain" }, [ "text\n" ] ];
	}
	if ( path eq "/binary" ) {
		return [ 200, {{}}, to_binary( "binary\n" ) ];
	}
	if ( path eq "/path" ) {
		return [ 200, {{}}, new Path(' . zuzu_string($text_path) . ') ];
	}
	return [ 404, { "Content-Type": "text/plain" }, [ "missing\n" ] ];
}
',
	);
	my $app = Zuzu::Web::PSGI->app( script => $script );

	test_psgi app => $app, client => sub {
		my ( $cb ) = @_;

		is( $cb->( GET '/text' )->content, "text\n", 'compat text route' );
		is( $cb->( GET '/binary' )->content, "binary\n", 'compat binary route' );
		is( $cb->( GET '/path' )->content, "static text\n", 'compat Path route' );
	};
}

done_testing;
