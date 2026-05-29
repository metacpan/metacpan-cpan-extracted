use utf8;
use strict;
use warnings;

use Test2::V0;

use File::Spec;
use File::Temp qw( tempdir );
use IPC::Run qw( run );

sub write_file {
	my ( $path, $content ) = @_;

	open my $fh, '>:encoding(UTF-8)', $path
		or die "Could not create $path: $!";
	print {$fh} $content;
	close $fh;

	return $path;
}

sub slurp_file {
	my ( $path ) = @_;

	open my $fh, '<:encoding(UTF-8)', $path
		or die "Could not read $path: $!";
	local $/;
	my $content = <$fh>;
	close $fh;

	return $content;
}

sub zuzu_string {
	my ( $value ) = @_;

	$value =~ s/\\/\\\\/g;
	$value =~ s/"/\\"/g;
	$value =~ s/\n/\\n/g;
	$value =~ s/\r/\\r/g;
	$value =~ s/\t/\\t/g;

	return '"' . $value . '"';
}

sub run_zuzu {
	my ( $script, $env ) = @_;

	my @cmd = (
		$^X,
		'bin/zuzu.pl',
		'-Istdlib/modules',
		'-Istdlib/test-modules',
		$script,
	);
	my $stdout = '';
	my $stderr = '';
	my $ok = eval {
		local %ENV = ( %ENV, %{ $env // {} } );
		run( \@cmd, '<', \undef, '>', \$stdout, '2>', \$stderr );
		1;
	};

	return {
		ok => $ok ? 1 : 0,
		status => $?,
		exit => $? >> 8,
		stdout => $stdout,
		stderr => $stderr,
		error => $@,
	};
}

my $tmpdir = tempdir( CLEANUP => 1 );

my $record_path = File::Spec->catfile( $tmpdir, 'demolished.txt' );
my $finish_script = write_file(
	File::Spec->catfile( $tmpdir, 'finish.zzs' ),
	join(
		"\n",
		'from std/io import Path;',
		'',
		'class Recorder {',
		'	let String path;',
		'	let String message;',
		'',
		'	method __demolish__ () {',
		'		( new Path( path: path ) ).append_utf8(message);',
		'	}',
		'}',
		'',
		'let alive := new Recorder(',
		'	path: ' . zuzu_string($record_path) . ',',
		'	message: "alive\n",',
		');',
		'{',
		'	let scoped := new Recorder(',
		'		path: ' . zuzu_string($record_path) . ',',
		'		message: "scoped\n",',
		'	);',
		'}',
		'',
	),
);

my $finish_run = run_zuzu($finish_script);
is( $finish_run->{exit}, 0, 'script with surviving demolish hook exits 0' )
	or diag $finish_run->{stdout}, $finish_run->{stderr}, $finish_run->{error};
is(
	slurp_file($record_path),
	"scoped\nalive\n",
	'finish runs surviving demolish hook after scoped cleanup',
);

my $session_run = run_zuzu(
	'stdlib/tests/std/web/session.zzs',
	{
		FIXTURE_DIR => File::Spec->catdir(
			File::Spec->rel2abs(File::Spec->curdir),
			'stdlib',
			'test-fixtures',
		),
	},
);
is( $session_run->{exit}, 0, 'std/web/session ztest exits 0' )
	or diag $session_run->{stdout}, $session_run->{stderr}, $session_run->{error};
like( $session_run->{stdout}, qr/^1\.\.10$/m, 'session ztest prints TAP plan' );
unlike(
	$session_run->{stdout} . $session_run->{stderr},
	qr/DESTROY created new reference to dead object/,
	'session ztest has no global destruction resurrection warning',
);

done_testing;
