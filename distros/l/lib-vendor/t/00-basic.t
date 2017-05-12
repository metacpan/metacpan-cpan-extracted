#! /usr/bin/env perl

use Test::More tests => 15;

ok require lib::vendor, 'Required lib::vendor';

like $lib::vendor::APPDIR, qr/\bt$/, '$APPDIR is set to t directory';

my $INC_size = @INC;
@INC = (@INC, @INC);
cmp_ok lib::vendor::shrink_INC(), '<=', $INC_size, 'shrink_INC worked';
cmp_ok 1, '<', scalar @INC, 'shrink_INC did not shrink @INC to 1';

foreach my $import (
    [],
    [ File::Spec->catdir( qw(vendor alpha lib) ), 'alpha' ],
    [ File::Spec->catdir( qw(bravo lib) ), -vendor => '', 'bravo' ]
) {
    my $path = shift @$import;

    my @old_INC = @INC;
    ok( lib::vendor->import(@$import), 'Import succeeds' );
    my @new_INC = @INC;

    my $tlib = File::Spec->catdir( $lib::vendor::APPDIR, 'lib' );
    is $INC[0], $tlib, "First entry in \@INC has t/lib";

    if ( $path ) {
        my $fullpath = File::Spec->catdir( $lib::vendor::APPDIR, $path );
        is $INC[1], $fullpath, "Next entry in \@INC has $path";
    }

    unless (
        is scalar @new_INC, 1 + scalar @old_INC,
            "\@INC has one more entry for '" . join("', '", @$import) . "'"
    ) {
        diag 'Old:';
        diag $_ for @old_INC;
        diag 'New:';
        diag $_ for @new_INC;
    }
}

