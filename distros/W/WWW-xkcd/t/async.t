#!/usr/bin/perl
use strict;
use warnings;

use WWW::xkcd;
use Test::More;

# check for AnyEvent and AnyEvent::HTTP
eval 'use AnyEvent';
$@ and plan skip_all => 'AnyEvent required for this test';

eval 'use AnyEvent::HTTP';
$@ and plan skip_all => 'AnyEvent::HTTP required for this test';

# actual test
plan tests => 20;

my $x = WWW::xkcd->new;

sub check_meta {
    my $meta = shift;
    ok( $meta, 'Successful fetch' );
    is( ref $meta, 'HASH', 'Correct type of meta' );
    ok( exists $meta->{'title'}, 'Got title in meta' );

    if ( shift ) {
        is( $meta->{'title'}, 'Ferret', 'Got correct title' );
    }
}

sub check_comic {
    my $img = shift;
    ok( $img, 'Got comic image' );
}

my $cv = AnyEvent->condvar;

foreach my $param ( undef, 20 ) {
    my @params = defined $param ? ($param) : ();
    $cv->begin;

    $x->fetch_metadata( @params, sub {
        my $meta = shift;
        check_meta( $meta, @params );

        $cv->end;
    } );

    $cv->begin;
    $x->fetch( @params, sub {
        my ( $img, $meta ) = @_;
        check_meta( $meta, @params );
        check_comic($img);

        $cv->end;
    } );
}

$cv->begin;
$x->fetch_random( sub {
        my ( $img, $meta ) = @_;
        check_meta($meta);
        check_comic($img);

        $cv->end;
    } );


$cv->recv;



