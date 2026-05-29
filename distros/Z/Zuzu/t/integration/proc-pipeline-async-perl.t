use utf8;
use strict;
use warnings;

use Test2::V0;

use File::Spec;
use File::Temp qw( tempdir );
use IPC::Run qw( run );

my $supports_true_pipeline = $^O !~ /^(?:MSWin32|dos|os2|VMS)\z/;
skip_all 'true Proc.pipeline_async streaming is Unix-only'
	if !$supports_true_pipeline;

my $repo_root = File::Spec->rel2abs( File::Spec->curdir );
my $tmp = tempdir( CLEANUP => 1 );
my $marker = File::Spec->catfile( $tmp, 'consumer-started' );
my $script = File::Spec->catfile( $tmp, 'pipeline-streaming.zzs' );

open my $fh, '>:encoding(UTF-8)', $script
	or die "Could not write test script: $!";
print {$fh} <<"ZZS";
from std/proc import Proc;
from test/more import *;

async function main () {
	let marker := "$marker";
	let producer :=
		"\$|=1; my \$marker = shift; "
		_ "print qq<go\\\\n>; "
		_ "for (1..100) { "
		_ "exit 0 if -e \$marker; "
		_ "select undef, undef, undef, 0.01; "
		_ "} exit 7;";
	let consumer :=
		"my \$marker = shift; "
		_ "open my \$fh, q{>}, \$marker or die \$!; "
		_ "print {\$fh} qq<started\\\\n>; "
		_ "close \$fh; "
		_ "while (<STDIN>) { print uc(\$_); }";
	let pipeline := await {
		Proc.pipeline_async(
			[
				[
					"perl",
					"-e",
					producer,
					marker,
				],
				[
					"perl",
					"-e",
					consumer,
					marker,
				],
			],
			{ timeout: 2 },
		);
	};

	ok( pipeline{ok}, "pipeline_async streams before upstream exits" );
	is( pipeline{stdout}, "GO\\n", "pipeline_async returns downstream stdout" );
	ok( pipeline{steps}[0]{ok}, "producer exits successfully" );
	ok( pipeline{steps}[1]{ok}, "consumer exits successfully" );
}

await {
	main();
};

done_testing();
ZZS
close $fh;

my $stdout = '';
my $stderr = '';
my $ok = run(
	[ $^X, File::Spec->catfile( $repo_root, 'bin', 'zuzu.pl' ), $script ],
	'>',
	\$stdout,
	'2>',
	\$stderr,
);

ok( $ok, 'zuzu process exits successfully' )
	or diag $stderr;
like( $stdout, qr/^ok 1 - pipeline_async streams before upstream exits/m,
	'streaming assertion passes' );
like( $stdout, qr/^ok 2 - pipeline_async returns downstream stdout/m,
	'stdout assertion passes' );
like( $stdout, qr/^1\.\.4/m, 'inner TAP plan is present' );
is( $stderr, '', 'no stderr output' );

done_testing();
