#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Temp qw( tempdir );
use Getopt::Long qw( GetOptions );
use JSON::PP qw( encode_json );
use MIME::Base64 qw( encode_base64 );
use Path::Tiny;
use Time::HiRes qw( time );

my %commands = (
	perl => './bin/zuzu.pl -It/modules',
	rust => './extras/zuzu-rust/target/release/zuzu-rust -It/modules',
	'js-node' => './extras/zuzu-js/bin/zuzu-js -It/modules',
	'js-electron' =>
		'./extras/zuzu-js/node_modules/.bin/electron '
		. 'extras/zuzu-js/bin/zuzu-js-electron',
);

my %opt = (
	iterations => 6,
	warmup => 1,
	impl => [qw( perl rust js-node )],
);

GetOptions(
	'iterations=i' => \$opt{iterations},
	'warmup=i' => \$opt{warmup},
	'impl=s@' => \$opt{impl},
	'json' => \$opt{json},
) or die "Invalid options for std-marshal-phase36 benchmark\n";

my @impls = map { split /,/ } @{ $opt{impl} };
my $tmp_dir = tempdir( 'std-marshal-phase36-XXXXXX', TMPDIR => 1, CLEANUP => 1 );
my %cases = _benchmark_cases();
my %results;

for my $impl (@impls) {
	die "Unknown implementation '$impl'\n" if !exists $commands{$impl};
	for my $case ( sort keys %cases ) {
		my $source = _benchmark_source(
			fixture => $cases{$case},
			iterations => $opt{iterations},
			warmup => $opt{warmup},
		);
		my $path = path( $tmp_dir, "$impl-$case.zzs" );
		$path->spew_utf8($source);

		my $start = time;
		my $output = _run_command( $commands{$impl}, "$path" );
		my $elapsed = time - $start;
		die "$impl $case benchmark failed:\n$output\n"
			if $output !~ /^ok 1 - marshal benchmark completed/m;

		$results{$impl}{$case} = {
			iterations => $opt{iterations},
			warmup_iterations => $opt{warmup},
			total_seconds => sprintf( '%.9f', $elapsed ) + 0,
			seconds_per_iteration => sprintf(
				'%.9f',
				$elapsed / $opt{iterations},
			) + 0,
		};
	}
}

my $report = {
	benchmark => 'std-marshal-phase36',
	generated_at_epoch => time,
	results => \%results,
};

if ( $opt{json} ) {
	print encode_json($report) . "\n";
	exit 0;
}

for my $impl ( sort keys %{ $report->{results} } ) {
	for my $case ( sort keys %{ $report->{results}{$impl} } ) {
		my $r = $report->{results}{$impl}{$case};
		printf "%s\t%s\titerations=%d\ttotal_seconds=%.9f\tseconds_per_iteration=%.9f\n",
			$impl,
			$case,
			$r->{iterations},
			$r->{total_seconds},
			$r->{seconds_per_iteration};
	}
}

sub _benchmark_cases {
	my $binary = encode_base64( ( '0123456789abcdef' x 4096 ), '' );
	return (
		large_array => <<'ZZS',
let fixture_value := [];
let i := 0;
while ( i < 2000 ) {
	fixture_value.push(i);
	i := i + 1;
}
ZZS
		nested_dicts => <<'ZZS',
let fixture_value := new Dict();
let i := 0;
while ( i < 250 ) {
	let child := new Dict();
	child.set( "i", i );
	child.set( "label", "item-" _ i );
	child.set( "values", [ i, i + 1, i + 2 ] );
	fixture_value.set( "k" _ i, child );
	i := i + 1;
}
ZZS
		large_binary => _large_binary_fixture($binary),
		cyclic_graph => <<'ZZS',
let fixture_value := [];
let cursor := fixture_value;
let i := 0;
while ( i < 250 ) {
	let child := [ cursor, i ];
	cursor.push(child);
	cursor := child;
	i := i + 1;
}
fixture_value.push(fixture_value);
ZZS
		code_heavy => _code_heavy_fixture(),
	);
}

sub _large_binary_fixture {
	my ($binary) = @_;
	my @chunks = $binary =~ /.{1,72}/g;
	my $literal = join " _\n\t", map { qq{"$_"} } @chunks;
	return <<~"ZZS";
		from std/string/base64 import decode;
		let fixture_value := decode(
			$literal
		);
		ZZS
}

sub _code_heavy_fixture {
	my @lines = (
		'const marshal_phase36_offset := 1;',
		'function bench_fn_0 (x) { return x + marshal_phase36_offset; }',
	);
	for my $i ( 1 .. 24 ) {
		my $prev = $i - 1;
		push @lines,
			"function bench_fn_$i (x) { return bench_fn_$prev(x) + 1; }";
	}
	push @lines, <<'ZZS';
class MarshalPhase36Box {
	let Number x := 1;

	method total () -> Number {
		return bench_fn_24(x);
	}
}

let fixture_value := [
	MarshalPhase36Box,
	new MarshalPhase36Box( x: 5 ),
];
ZZS
	return join( "\n", @lines ) . "\n";
}

sub _benchmark_source {
	my (%args) = @_;
	my $iterations = $args{iterations};
	my $warmup = $args{warmup};
	return <<~"ZZS";
		from std/marshal import dump, load;
		$args{fixture}

		let marshal_bench_i := 0;
		while ( marshal_bench_i < $warmup ) {
			load( dump(fixture_value) );
			marshal_bench_i := marshal_bench_i + 1;
		}

		marshal_bench_i := 0;
		while ( marshal_bench_i < $iterations ) {
			load( dump(fixture_value) );
			marshal_bench_i := marshal_bench_i + 1;
		}
		say("1..1");
		say("ok 1 - marshal benchmark completed");
		ZZS
}

sub _run_command {
	my ( $command, $path ) = @_;
	my $cmd = $command . ' ' . _shell_quote($path) . ' 2>&1';
	my $output = qx{$cmd};
	die "Command failed with exit code " . ( $? >> 8 ) . ":\n$output\n"
		if $?;
	return $output;
}

sub _shell_quote {
	my ($value) = @_;
	$value =~ s/'/'"'"'/g;
	return "'$value'";
}
