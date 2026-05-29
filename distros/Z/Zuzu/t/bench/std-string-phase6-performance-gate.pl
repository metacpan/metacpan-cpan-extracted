#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Spec;
use FindBin qw( $Bin );
use JSON::PP qw( decode_json );

my $threshold_file = File::Spec->catfile( $Bin, 'std-string-phase6-thresholds.json' );
my $benchmark_file = File::Spec->catfile( $Bin, 'std-string-phase6-benchmark.json' );

my $iterations = $ENV{STD_STRING_PHASE6_BENCH_ITERATIONS};
$iterations = 400 if !defined $iterations or $iterations !~ /^\d+$/;

my $warmup = $ENV{STD_STRING_PHASE6_BENCH_WARMUP};
$warmup = 40 if !defined $warmup or $warmup !~ /^\d+$/;

my $cmd = join ' ',
	$^X,
	File::Spec->catfile( $Bin, 'std-string-phase6.pl' ),
	'--json',
	'--iterations',
	$iterations,
	'--warmup',
	$warmup;

my $benchmark_json = `$cmd`;
if ( $? != 0 ) {
	die "Could not execute std-string-phase6 benchmark\n";
}

open my $bench_fh, '>', $benchmark_file
	or die "Could not write $benchmark_file: $!\n";
print {$bench_fh} $benchmark_json;
close $bench_fh;

my $report_raw = _slurp( $benchmark_file );
my $threshold_raw = _slurp( $threshold_file );
my $report = decode_json( $report_raw );
my $threshold = decode_json( $threshold_raw );

my $allowed = $threshold->{allowed_regression_percent};
$allowed = 0 if !defined $allowed;

my @ops = sort keys %{ $threshold->{minimum_ops_per_second} || {} };
if ( !@ops ) {
	die "No std-string-phase6 thresholds were defined\n";
}

my $failures = 0;
print "std/string phase6 performance thresholds\n";
print "iterations=$iterations warmup=$warmup allowed_regression_percent=$allowed\n";

for my $name ( @ops ) {
	my $floor = $threshold->{minimum_ops_per_second}{$name};
	my $actual = $report->{results}{$name}{ops_per_second};

	if ( !defined $actual ) {
		$failures++;
		print "[FAIL] $name has no measured ops/sec\n";
		next;
	}

	my $protected_floor = $floor * ( 1 - ( $allowed / 100 ) );
	if ( $actual + 0 < $protected_floor ) {
		$failures++;
		printf "[FAIL] %s ops/sec %.2f below protected floor %.2f (baseline %.2f)\n",
			$name,
			$actual,
			$protected_floor,
			$floor;
		next;
	}

	printf "[PASS] %s ops/sec %.2f >= %.2f (baseline %.2f)\n",
		$name,
		$actual,
		$protected_floor,
		$floor;
}

if ( $failures ) {
	die "std/string phase6 performance regression gate failed ($failures failures)\n";
}

exit 0;

sub _slurp {
	my ( $file ) = @_;

	open my $fh, '<', $file
		or die "Could not open $file: $!\n";
	local $/;
	my $raw = <$fh>;
	close $fh;
	return $raw;
}
