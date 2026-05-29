#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Benchmark qw( cmpthese );
use Getopt::Long qw( GetOptions );
use JSON::PP qw( encode_json );
use Time::HiRes qw( time );
use FindBin qw( $Bin );
use lib "$Bin/../../lib";

use Zuzu::Parser;
use Zuzu::Runtime;

my %opt = (
	iterations => 2000,
	warmup => 100,
);

GetOptions(
	'json' => \$opt{json},
	'iterations=i' => \$opt{iterations},
	'warmup=i' => \$opt{warmup},
) or die "Invalid options for core1-baseline benchmark\n";

my $src = <<'ZZS';
function add ( a, b ) {
	return a + b;
}

let out := [];
for ( let i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] ) {
	out.push( add( i, i + 1 ) );
}
out.length();
ZZS

my $parser = Zuzu::Parser->new;
my $ast = $parser->parse( $src, '<bench>' );

if ( $opt{json} ) {
	my $report = _run_json_benchmark(
		$parser,
		$ast,
		$src,
		$opt{iterations},
		$opt{warmup},
	);
	print encode_json( $report ) . "\n";
	exit 0;
}

cmpthese(
	-3,
	{
		parse => sub {
			$parser->parse( $src, '<bench>' );
		},
		run_hot => sub {
			my $runtime = Zuzu::Runtime->new;
			$runtime->evaluate( $ast );
		},
	},
);

sub _run_json_benchmark {
	my ( $parser, $ast, $source, $iterations, $warmup ) = @_;

	for ( 1 .. $warmup ) {
		$parser->parse( $source, '<bench>' );
		my $runtime = Zuzu::Runtime->new;
		$runtime->evaluate( $ast );
	}

	my %results = (
		parse => _measure_iterations(
			sub {
				$parser->parse( $source, '<bench>' );
			},
			$iterations,
		),
		run_hot => _measure_iterations(
			sub {
				my $runtime = Zuzu::Runtime->new;
				$runtime->evaluate( $ast );
			},
			$iterations,
		),
	);

	return {
		benchmark => 'core1-baseline',
		generated_at_epoch => time,
		iterations => $iterations,
		warmup_iterations => $warmup,
		perl_version => $^V . '',
		results => \%results,
	};
}

sub _measure_iterations {
	my ( $runner, $iterations ) = @_;
	my $start = time;

	for ( 1 .. $iterations ) {
		$runner->();
	}

	my $elapsed = time - $start;
	my $ops_per_sec = $elapsed > 0 ? $iterations / $elapsed : 0;

	return {
		total_seconds => sprintf( '%.9f', $elapsed ) + 0,
		ops_per_second => sprintf( '%.2f', $ops_per_sec ) + 0,
	};
}
