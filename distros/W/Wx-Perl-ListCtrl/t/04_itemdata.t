#!/usr/bin/perl -w

use strict;
use Test::More tests => 77;

use lib 't';
use Wx qw(:listctrl);
use Wx::Perl::ListCtrl;
use MyTest;

my %foos;

{
    package Foo;

    sub new { $foos{$_[1]} = 1; bless [ $_[1] ], __PACKAGE__ }
    sub DESTROY { delete $foos{$_[0][0]} }
}

sub data($) { +{ $_[0] => [ "X $_[0]" ] } }
sub obj($)  { Foo->new( $_[0] ) }
sub has($)  { exists $foos{$_[0]} }

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

    # sanity checking
#   diag "all empty";
    check( $lc, {} );

#   diag "two items";
    $lc->SetItemData( 0, data 0 );
    $lc->SetItemData( 5, data 5 );
    check( $lc, { 1 => 1, 6 => 6 } );

#   diag "one deleted";
    $lc->SetItemData( 0, undef );
    check( $lc, { 6 => 6 } );

    # interaction with InsertItem, DeleteItem, ...
#   diag "insert and delete";
    foreach ( 0 .. $lc->GetItemCount - 1 ) {
        $lc->SetItemData( $_, data $_ ) if $_ & 1;
    }
    check( $lc, { 2 => 2, 4 => 4, 6 => 6, 8 => 8 } );

#   diag "insert";
    $lc->InsertStringItem( 3, "Test" );
    check( $lc, { 2 => 2, 5 => 4, 7 => 6, 9 => 8 } );

#   diag "delete";
    $lc->DeleteItem( 8 );
    check( $lc, { 2 => 2, 5 => 4, 7 => 6 } );

#   diag "more deletion";
    $lc->DeleteItem( 4 );
    check( $lc, { 2 => 2, 6 => 6 } );

#   diag "clear";
    $lc->DeleteAllItems;
    check( $lc, {} );

#   diag "sanity";
    init( $lc, 8, 2 );
    check( $lc, {} );

    # check that item data is actually deleted
    $lc->SetItemData( 0, obj 0 );
    $lc->SetItemData( 5, obj 5 );
    ok( has 0 );
    ok( has 5 );

    $lc->DeleteItem( 1 );
    ok( has 0 );
    ok( has 5 );

    $lc->DeleteItem( 4 ); # all items shifted by 1 after deletion
    ok( has 0 );
    ok( !has 5 );

    $lc->SetItemData( 0, obj 7 );
    ok( !has 0 );
    ok( has 7 );

    $lc->SetItemData( 0, undef );
    ok( !has 7 );

    # fixes by Mark Dootson
    init( $lc, 8, 2 );

    $lc->SetItemData( 0, 'item 0' );
    $lc->SetItemData( 2, 'item 2' );

    is( $lc->GetItemData( 2 ), 'item 2' );
    ok( !defined $lc->GetItemData( 1 ) );

    my @item = $lc->GetItemData( 1 );

    is( 1, scalar @item );
    ok( !defined $item[0] );
};
