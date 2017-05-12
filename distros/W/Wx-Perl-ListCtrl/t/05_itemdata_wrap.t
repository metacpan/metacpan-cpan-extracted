#!/usr/bin/perl -w

use strict;
use Test::More tests => 26;

use lib 't';
use Wx qw(:listctrl);
use Wx::Perl::ListCtrl;
use MyTest;
use Config;

sub data($) { +{ $_[0] => [ "X $_[0]" ] } }

sub check($$) {
    my( $lc, $items ) = @_;

    foreach my $i ( 1 .. $lc->GetItemCount ) {
        if( exists $items->{$i} ) {
            is_deeply( $lc->GetItemData( $i - 1 ), data $items->{$i} - 1,
                       "Full: $i" );
        } else {
            is( $lc->GetItemData( $i - 1 ), undef, "Empty: $i" );
        }
    }

}

test {
    my $frame = shift;
    my $lc = Wx::Perl::ListCtrl->new( $frame, -1, [-1, -1], [-1, -1],
                                       wxLC_REPORT );
    init( $lc, 8, 2 );

    $lc->SetItemData( 0, data 0 );
    $lc->SetItemData( 5, data 5 );
    check( $lc, { 1 => 1, 6 => 6 } );

    # simulate many calls
    my $size = $Config{ivsize} * 8;
    my $count = $lc->{_wx_count} = Wx::Perl::ListCtrl::_max_itemdata_idx() + 2;

    $lc->SetItemData( 2, data 2 );
    ok( $lc->{_wx_count} < $count, "The control wrapped" );

    check( $lc, { 1 => 1, 6 => 6, 3 => 3 } );

    $count = $lc->{_wx_count};
    $lc->SetItemData( 3, data 3 );
    ok( $lc->{_wx_count} > $count, "The control did not wrap" );
    check( $lc, { 1 => 1, 6 => 6, 3 => 3, 4 => 4 } );
};
