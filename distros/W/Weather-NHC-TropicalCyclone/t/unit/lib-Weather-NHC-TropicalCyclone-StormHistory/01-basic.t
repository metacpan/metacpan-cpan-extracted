use strict;
use warnings;
use Test::More;

use_ok q{Weather::NHC::TropicalCyclone::StormTable};

my $obj = Weather::NHC::TropicalCyclone::StormTable->new;
isa_ok $obj, q{Weather::NHC::TropicalCyclone::StormTable};

can_ok $obj, qw/new storm_table _get_storm_designation get_history_archive_url get_best_track_archive_url get_fixes_archive_url get_archive_url get_by_year_basin _return_arrayref years by_year names by_name basins by_basin nhc_designations by_nhc_designation storm_kinds by_storm_kind _data _parse_line/;

foreach my $year ( @{ $obj->years } ) {
    ok $year >= 1851, q{Year is >= 1851};
}

foreach my $basins ( @{ $obj->basins } ) {
    ok $basins, q{Basin is defined};
}

foreach my $names ( @{ $obj->names } ) {
    ok $names, q{Name is defined};
}

foreach my $storm_kinds ( @{ $obj->storm_kinds } ) {
    ok $storm_kinds, q{Storm kind is defined};
}

foreach my $nhc_designations ( @{ $obj->nhc_designations } ) {
    ok $nhc_designations, q{Storm designations is defined};
}

foreach my $year ( @{ $obj->years } ) {
    like $obj->get_archive_url($year), qr/https/, q{got what looks like a URL};
    foreach my $storm ( @{ $obj->by_year($year) } ) {
        my $line       = $obj->_parse_line($storm);
        my $basin      = $line->[1];
        my $storm_num  = $line->[7];
        my $storm_year = $line->[8];
        my $storm_kind = $line->[9];
        is $year, $storm_year, q{year matches};
        like $obj->get_history_archive_url( $year, $basin, $storm_num ),    qr/https/, q{got what looks like a URL};
        like $obj->get_best_track_archive_url( $year, $basin, $storm_num ), qr/https/, q{got what looks like a URL};
        like $obj->get_fixes_archive_url( $year, $basin, $storm_num ),      qr/https/, q{got what looks like a URL};
    }
}

done_testing();
