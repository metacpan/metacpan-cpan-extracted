use utf8;
use strict;
use warnings;

use Test2::V0;

use File::Spec;
use File::Temp qw( tempdir );

use Zuzu::Web::PSGI::CLI;

sub write_script {
	my ( $dir, $name, $source ) = @_;

	my $path = File::Spec->catfile( $dir, $name );
	open my $fh, '>:encoding(UTF-8)', $path
		or die "Could not create $path: $!";
	print {$fh} $source;
	close $fh;

	return $path;
}

sub capture_run {
	my ( @args ) = @_;
	my $stdout = '';
	my $stderr = '';

	open my $out_fh, '>', \$stdout
		or die "Could not capture STDOUT: $!";
	open my $err_fh, '>', \$stderr
		or die "Could not capture STDERR: $!";

	my $exit;
	{
		local *STDOUT = $out_fh;
		local *STDERR = $err_fh;
		$exit = Zuzu::Web::PSGI::CLI::run(@args);
	}

	return ( $exit, $stdout, $stderr );
}

my $tmpdir = tempdir( CLEANUP => 1 );
my $valid_script = write_script(
	$tmpdir,
	'valid.zzs',
	<<'ZUZU',
function __request__ ( env ) {
	return [
		200,
		{ "Content-Type": "text/plain" },
		[ "ok" ],
	];
}
ZUZU
);
my $missing_request_script = write_script(
	$tmpdir,
	'missing-request.zzs',
	"let answer := 42;\n",
);

{
	no warnings 'redefine';
	local *Zuzu::Web::PSGI::CLI::_run_plack = sub {
		die '_run_plack should not be called for --check';
	};

	my ( $exit, $stdout, $stderr ) = capture_run( '--check', $valid_script );
	is( $exit, 0, '--check valid app exits 0' );
	is( $stdout, '', '--check valid app is quiet on STDOUT' );
	is( $stderr, '', '--check valid app is quiet on STDERR' );
}

{
	my ( $exit, undef, $stderr ) = capture_run(
		'--check',
		$missing_request_script,
	);

	is( $exit, 1, 'missing __request__ exits 1' );
	like( $stderr, qr/does not define __request__/, 'startup error is printed' );
}

{
	my ( $exit, undef, $stderr ) = capture_run();

is( $exit, 2, 'missing script exits 2' );
like(
	$stderr,
	qr/Missing ZuzuScript web application path/,
	'usage error names missing script',
);
}

{
	my ( $exit, undef, $stderr ) = capture_run( '-d=cat', $valid_script );

	is( $exit, 2, 'bad debug value exits 2' );
	like( $stderr, qr/Debug level/, 'bad debug value reports debug issue' );
}

{
	my ( $exit, undef, $stderr ) = capture_run( '-h' );

	is( $exit, 0, 'help exits 0' );
	like( $stderr, qr/Usage: zuzu-plackup\.pl/, 'help prints usage' );
}

{
	my %captured;
	no warnings 'redefine';
	local *Zuzu::Web::PSGI::app = sub {
		my ( $class, %args ) = @_;
		%captured = %args;
		return sub { [ 200, [], [] ] };
	};
	local *Zuzu::Web::PSGI::CLI::_run_plack = sub { return };

	my ( $exit ) = capture_run(
		'-Istdlib/test-modules',
		'--deny=fs,net',
		'--denymodule=perl,std/io',
		'-d',
		$valid_script,
	);

	is( $exit, 0, 'Zuzu options are accepted' );
	is( $captured{script}, $valid_script, 'script is passed to app builder' );
	is( $captured{lib}, [ 'stdlib/test-modules' ], 'include paths are passed through' );
	is( $captured{deny}, [ 'fs', 'net' ], 'deny values are normalized' );
	is(
		$captured{deny_modules},
		[ 'perl', 'std/io' ],
		'denymodule values are normalized',
	);
	is( $captured{debug_level}, 1, '-d without value sets debug level 1' );
}

{
	my @captured_plack_args;
	no warnings 'redefine';
	local *Zuzu::Web::PSGI::CLI::_run_plack = sub {
		my ( $app, $plack_args ) = @_;
		@captured_plack_args = @$plack_args;
		return;
	};

	my ( $exit ) = capture_run(
		$valid_script,
		'--',
		'-p',
		'5000',
		'-s',
		'HTTP::Server::PSGI',
	);

	is( $exit, 0, 'serve mode exits 0 when runner returns' );
	is(
		\@captured_plack_args,
		[ '-p', '5000', '-s', 'HTTP::Server::PSGI' ],
		'Plack args after -- are passed through unchanged',
	);
}

done_testing;
