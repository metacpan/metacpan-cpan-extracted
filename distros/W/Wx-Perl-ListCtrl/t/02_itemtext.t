#!/usr/bin/perl -w

use strict;
use Test::More tests => 5;

use lib 't';
use Wx qw(:listctrl);
use Wx::Perl::ListCtrl;
use MyTest;

test {
    my $frame = shift;
    my $lc = Wx::Perl::ListCtrl->new( $frame, -1, [-1, -1], [-1, -1],
                                      wxLC_SINGLE_SEL|wxLC_REPORT );

    init( $lc, 3, 4 );

    is( $lc->GetItemText( 0, 0 ), "(R1, C1)" );
    is( $lc->GetItemText( 0, 2 ), "(R1, C3)" );
    is( $lc->GetItemText( 2, 0 ), "(R3, C1)" );

    $lc->SetItemText( 0, 0, "Y1, X1" );
    $lc->SetItemText( 0, 2, "Y1, X3" );

    is( $lc->GetItemText( 0, 0 ), "Y1, X1" );
    is( $lc->GetItemText( 0, 2 ), "Y1, X3" );
};
