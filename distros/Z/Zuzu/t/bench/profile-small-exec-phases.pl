#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Getopt::Long qw( GetOptions );
use JSON::PP qw( decode_json encode_json );
use List::Util qw( sum min max );
use Time::HiRes qw( time );

my %opt = (
	iterations => 80,
);

GetOptions(
	'iterations=i' => \$opt{iterations},
	'json' => \$opt{json},
) or die "Invalid options\n";

my $child_source = <<'ZZS';
function add ( a, b ) {
	return a + b;
}

let total := 0;
for ( let i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] ) {
	total += add( i, i + 1 );
}
total;
ZZS

my @startup;
my @parse;
my @runtime;
my @total;

for ( 1 .. $opt{iterations} ) {
	my $payload = _run_child( $child_source );
	push @startup, $payload->{startup_seconds};
	push @parse, $payload->{parse_seconds};
	push @runtime, $payload->{runtime_seconds};
	push @total, $payload->{total_seconds};
}

my %report = (
	benchmark => 'perl-small-exec-phases',
	iterations => $opt{iterations},
	generated_at_epoch => time,
	phases => {
		startup => _stats( \@startup, \@total ),
		parse => _stats( \@parse, \@total ),
		runtime => _stats( \@runtime, \@total ),
		total => _stats( \@total, undef ),
	},
);

if ( $opt{json} ) {
	print encode_json( \%report ) . "\n";
	exit 0;
}

print "Iterations: $report{iterations}\n";
for my $phase ( qw( startup parse runtime total ) ) {
	my $s = $report{phases}{$phase};
	my $percent = exists $s->{mean_percent_of_total}
		? sprintf( ' (%5.1f%%)', $s->{mean_percent_of_total} )
		: '';
	printf "% -8s mean=%8.6f ms median=%8.6f ms min=%8.6f ms max=%8.6f ms%s\n",
		$phase,
		$s->{mean_ms},
		$s->{median_ms},
		$s->{min_ms},
		$s->{max_ms},
		$percent;
}

sub _run_child {
	my ( $source ) = @_;

	my $child = <<'PERL';
use strict;
use warnings;
use utf8;
use JSON::PP qw( encode_json );
use Time::HiRes qw( time );

my $source = do { local $/; <STDIN> };

my $t0 = time;
require lib;
lib->import( "./lib" );
require Zuzu::Parser;
require Zuzu::Runtime;
my $t1 = time;

my $parser = Zuzu::Parser->new;
my $ast = $parser->parse( $source, '<bench>' );
my $t2 = time;

my $runtime = Zuzu::Runtime->new;
my $result = $runtime->evaluate( $ast );
my $t3 = time;

print encode_json(
	{
		startup_seconds => $t1 - $t0,
		parse_seconds => $t2 - $t1,
		runtime_seconds => $t3 - $t2,
		total_seconds => $t3 - $t0,
		result => $result,
	}
);
PERL

	my $escaped_child = $child;
	$escaped_child =~ s/'/'"'"'/g;
	my $escaped_source = $source;
	$escaped_source =~ s/'/'"'"'/g;

	my $cmd = qq{perl -e '$escaped_child'};
	my $output = qx{printf "%s" '$escaped_source' | $cmd};
	if ( $? ) {
		die "Child benchmark failed: $?";
	}

	my $decoded = decode_json( $output );
	return $decoded;
}

sub _stats {
	my ( $values, $totals ) = @_;
	my @sorted = sort { $a <=> $b } @$values;
	my $count = scalar @sorted;
	my $sum_value = sum( @sorted );
	my $mean = $sum_value / $count;
	my $median = $count % 2
		? $sorted[ int( $count / 2 ) ]
		: ( $sorted[ $count / 2 - 1 ] + $sorted[ $count / 2 ] ) / 2;

	my %stats = (
		mean_ms => $mean * 1000,
		median_ms => $median * 1000,
		min_ms => min( @sorted ) * 1000,
		max_ms => max( @sorted ) * 1000,
	);

	if ( defined $totals ) {
		my $mean_total = sum( @$totals ) / scalar @$totals;
		$stats{mean_percent_of_total} = $mean_total > 0
			? ( $mean / $mean_total ) * 100
			: 0;
	}

	return \%stats;
}
