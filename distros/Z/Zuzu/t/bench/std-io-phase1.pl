#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Path qw( make_path remove_tree );
use File::Spec;
use Getopt::Long qw( GetOptions );
use JSON::PP qw( encode_json );
use Time::HiRes qw( time );
use FindBin qw( $Bin );
use lib "$Bin/../../lib";

use Zuzu::Parser;
use Zuzu::Runtime;

my %opt = (
	iterations => 300,
	warmup => 30,
);

GetOptions(
	'json' => \$opt{json},
	'iterations=i' => \$opt{iterations},
	'warmup=i' => \$opt{warmup},
) or die "Invalid options for std-io-phase1 benchmark\n";

my $bench_root = File::Spec->catdir(
	File::Spec->tmpdir,
	"zuzu_std_io_phase1_$$",
);
make_path( $bench_root );

my $payload_path = File::Spec->catfile( $bench_root, 'payload.txt' );
my @payload_lines = map { "line $_" } 1 .. 60;
_write_lines( $payload_path, \@payload_lines );

my %sources = (
	spew_utf8 => <<'ZZS',
from std/io import Path;
let p := Path.tempfile();
p.spew_utf8("alpha\nbeta\ngamma\n");
p.remove();
ZZS
	read_utf8 => <<'ZZS',
from std/io import Path;
let p := Path.tempfile();
p.spew_utf8("alpha\nbeta\ngamma\n");
let content := p.slurp_utf8();
p.remove();
ZZS
	each_line_utf8 => <<'ZZS',
from std/io import Path;
let p := new Path($PAYLOAD);
let total := 0;
p.each_line( function ( line ) {
	total := total + 1;
});
ZZS
);

$sources{each_line_utf8} =~ s/\$PAYLOAD/_zuzu_string_literal( $payload_path )/e;

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
	benchmark => 'std-io-phase1',
	generated_at_epoch => time,
	iterations => $opt{iterations},
	warmup_iterations => $opt{warmup},
	perl_version => $^V . '',
	results => \%results,
};

if ( $opt{json} ) {
	print encode_json( $report ) . "\n";
	remove_tree( $bench_root );
	exit 0;
}

for my $name ( sort keys %{ $report->{results} } ) {
	my $metric = $report->{results}{$name};
	printf "%s\tops_per_second=%.2f\ttotal_seconds=%.9f\n",
		$name,
		$metric->{ops_per_second},
		$metric->{total_seconds};
}

remove_tree( $bench_root );

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

sub _write_lines {
	my ( $path, $lines ) = @_;

	open my $fh, '>', $path
		or die "Could not write $path: $!\n";
	for my $line ( @{$lines} ) {
		print {$fh} "$line\n";
	}
	close $fh;
	return;
}

sub _zuzu_string_literal {
	my ( $value ) = @_;
	$value =~ s/\\/\\\\/g;
	$value =~ s/"/\\"/g;
	return qq{"$value"};
}
