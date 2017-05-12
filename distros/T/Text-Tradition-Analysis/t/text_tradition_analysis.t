#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Text::Tradition;
use Text::Tradition::Analysis qw/ run_analysis analyze_variant_location /;

my $datafile = 't/data/florilegium_tei_ps.xml';
my $tradition = Text::Tradition->new( 'input' => 'TEI',
                                      'name' => 'test0',
                                      'file' => $datafile );
my $s = $tradition->add_stemma( 'dotfile' => 't/data/florilegium.dot' );
is( ref( $s ), 'Text::Tradition::Stemma', "Added stemma to tradition" );

my %expected_genealogical = (
	1 => 0,
	2 => 1,
	3 =>  0,
	5 =>  0,
	7 =>  0,
	8 =>  0,
	10 => 0,
	13 => 1,
	33 => 0,
	34 => 0,
	37 => 0,
	60 => 0,
	81 => 1,
	84 => 0,
	87 => 0,
	101 => 0,
	102 => 0,
	122 => 1,
	157 => 0,
	166 => 1,
	169 => 1,
	200 => 0,
	216 => 1,
	217 => 1,
	219 => 1,
	241 => 1,
	242 => 1,
	243 => 1,
);

my $data = run_analysis( $tradition, calcdsn => 'dbi:SQLite:dbname=t/data/analysis.db' );
my $c = $tradition->collation;
foreach my $row ( @{$data->{'variants'}} ) {
	# Account for rows that used to be "not useful"
	unless( exists $expected_genealogical{$row->{'id'}} ) {
		$expected_genealogical{$row->{'id'}} = 1;
	}
	my $gen_bool = $row->{'genealogical'} ? 1 : 0;
	is( $gen_bool, $expected_genealogical{$row->{'id'}}, 
		"Got correct genealogical flag for row " . $row->{'id'} );
	# Check that we have the right row with the right groups
	my $rank = $row->{'id'};
	foreach my $rdghash ( @{$row->{'readings'}} ) {
		# Skip 'readings' that aren't really
		next unless $c->reading( $rdghash->{'readingid'} );
		# Check the rank
		is( $c->reading( $rdghash->{'readingid'} )->rank, $rank, 
			"Got correct reading rank" );
		# Check the witnesses
		my @realwits = sort $c->reading_witnesses( $rdghash->{'readingid'} );
		my @sgrp = sort @{$rdghash->{'group'}};
		is_deeply( \@sgrp, \@realwits, "Reading analyzed with correct groups" );
	}
}
is( $data->{'variant_count'}, 58, "Got right total variant number" );
# TODO Make something meaningful of conflict count, maybe test other bits
}




1;
