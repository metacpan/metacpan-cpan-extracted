#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Getopt::Long qw( GetOptions );
use JSON::PP qw( encode_json );
use Time::HiRes qw( time );
use FindBin qw( $Bin );
use lib "$Bin/../../lib";

use Zuzu::Parser;
use Zuzu::Runtime;

my %opt = (
	iterations => 400,
	warmup => 40,
);

GetOptions(
	'json' => \$opt{json},
	'iterations=i' => \$opt{iterations},
	'warmup=i' => \$opt{warmup},
) or die "Invalid options for std-string-phase6 benchmark\n";

my %sources = (
	split_join => <<'ZZS',
from std/string import split, join;
let parts := split("alpha,beta,gamma,delta,epsilon,zeta", ",");
let out := join("|", parts);
ZZS
	trim_search => <<'ZZS',
from std/string import trim, search;
let t := trim("    alpha beta gamma delta    ");
let m := search(t, /beta/);
ZZS
	case_convert => <<'ZZS',
from std/string import title, snake, kebab, camel;
let a := title("hello_world-value");
let b := snake("HelloWorld value");
let c := kebab("HelloWorld value");
let d := camel("hello_world value");
ZZS
);

my $parser = Zuzu::Parser->new;
my %asts;
for my $name ( sort keys %sources ) {
	$asts{$name} = $parser->parse( $sources{$name}, "<bench:$name>" );
}

for ( 1 .. $opt{warmup} ) {
	for my $name ( sort keys %asts ) {
		my $runtime = Zuzu::Runtime->new(
			lib => [ 'modules' ],
		);
		$runtime->evaluate( $asts{$name} );
	}
}

my %results;
for my $name ( sort keys %asts ) {
	$results{$name} = _measure_iterations(
		sub {
			my $runtime = Zuzu::Runtime->new(
				lib => [ 'modules' ],
			);
			$runtime->evaluate( $asts{$name} );
		},
		$opt{iterations},
	);
}

my $report = {
	benchmark => 'std-string-phase6',
	generated_at_epoch => time,
	iterations => $opt{iterations},
	warmup_iterations => $opt{warmup},
	perl_version => $^V . '',
	results => \%results,
};

if ( $opt{json} ) {
	print encode_json( $report ) . "\n";
	exit 0;
}

for my $name ( sort keys %{ $report->{results} } ) {
	my $metric = $report->{results}{$name};
	printf "%s\tops_per_second=%.2f\ttotal_seconds=%.9f\n",
		$name,
		$metric->{ops_per_second},
		$metric->{total_seconds};
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
