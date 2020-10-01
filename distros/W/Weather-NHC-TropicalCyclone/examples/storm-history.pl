#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};
use Weather::NHC::TropicalCyclone::StormTable ();
require Data::Dumper;

my $history = Weather::NHC::TropicalCyclone::StormTable->new();
print Data::Dumper::Dumper( $history->names );
print Data::Dumper::Dumper( $history->by_name(q{katrina}) );
print Data::Dumper::Dumper( $history->basins );
print Data::Dumper::Dumper( $history->by_basin(q{AL}) );
print Data::Dumper::Dumper( $history->nhc_designations );
print Data::Dumper::Dumper( $history->by_nhc_designation(q{al112019}) );
print Data::Dumper::Dumper( $history->storm_kinds );
print Data::Dumper::Dumper( $history->by_storm_kind(q{HU}) );
print Data::Dumper::Dumper( $history->years );
print Data::Dumper::Dumper( $history->by_year(q{2012}) );
print $history->get_history_archive_url( 2012, q{al}, q{01} ),    qq{\n};
print $history->get_best_track_archive_url( 2012, q{al}, q{01} ), qq{\n};
print $history->get_fixes_archive_url( 2012, q{al}, q{01} ),      qq{\n};
print $history->get_archive_url( 2012, q{al}, q{01} ),            qq{\n};
print Data::Dumper::Dumper( $history->get_storm_numbers( 1878, q{al} ) );

$history->get_latest_table;

print Data::Dumper::Dumper( $history->names );
print Data::Dumper::Dumper( $history->by_name(q{katrina}) );
print Data::Dumper::Dumper( $history->basins );
print Data::Dumper::Dumper( $history->by_basin(q{AL}) );
print Data::Dumper::Dumper( $history->nhc_designations );
print Data::Dumper::Dumper( $history->by_nhc_designation(q{al112019}) );
print Data::Dumper::Dumper( $history->storm_kinds );
print Data::Dumper::Dumper( $history->by_storm_kind(q{HU}) );
print Data::Dumper::Dumper( $history->years );
print Data::Dumper::Dumper( $history->by_year(q{2012}) );
print $history->get_history_archive_url( 2012, q{al}, q{01} ),    qq{\n};
print $history->get_best_track_archive_url( 2012, q{al}, q{01} ), qq{\n};
print $history->get_fixes_archive_url( 2012, q{al}, q{01} ),      qq{\n};
print $history->get_archive_url( 2012, q{al}, q{01} ),            qq{\n};
print Data::Dumper::Dumper( $history->get_storm_numbers( 1878, q{al} ) );
