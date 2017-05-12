#!/usr/bin/perl -w

use strict;
use Test::More tests => 9;

use lib 't';
use Wx qw(:listctrl);
use Wx::Perl::ListCtrl;
use MyTest;

test {
    my $frame = shift;
    my $slc = Wx::Perl::ListCtrl->new( $frame, -1, [-1, -1], [-1, -1],
                                       wxLC_SINGLE_SEL|wxLC_REPORT );
    init( $slc, 3, 4 );

    is( $slc->GetSelection, -1 );

    $slc->Select( 1, 1 );
    is( $slc->GetSelection, 1 );

    $slc->Select( 0, 1 );
    is( $slc->GetSelection, 0 );

    $slc->Select( 0, 0 );
    is( $slc->GetSelection, -1 );

    my $mlc = Wx::Perl::ListCtrl->new( $frame, -1, [-1, -1], [-1, -1],
                                       wxLC_REPORT );
    init( $mlc, 4, 4 );

    is_deeply( [ sort $mlc->GetSelections ], [] );

    $mlc->Select( 1, 1 );
    is_deeply( [ sort $mlc->GetSelections ], [ 1 ] );

    $mlc->Select( 1, 0 );
    is_deeply( [ sort $mlc->GetSelections ], [] );

    $mlc->Select( 1, 1 );
    $mlc->Select( 3, 1 );
    $mlc->Select( 2, 1 );
    $mlc->Select( 0, 0 );
    is_deeply( [ sort $mlc->GetSelections ], [ 1, 2, 3 ] );

    $mlc->Select( 3, 0 );
    is_deeply( [ sort $mlc->GetSelections ], [ 1, 2 ] );
};
