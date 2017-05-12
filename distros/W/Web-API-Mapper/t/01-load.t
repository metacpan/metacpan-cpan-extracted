#!/usr/bin/env perl
use Test::More tests => 27;

BEGIN {
    use lib 'lib';
    use_ok('Web::API::Mapper');
}


use Web::API::Mapper;
use warnings;
use strict;

{
    my $m = Web::API::Mapper->new( "/foo" => {
        post => [
            '/timeline/add/' => sub {
                my $args = shift;
                ok( $args->{name} , 'got name' );
                return "ok";
            },
        ],
        get => [
            '/timeline/get/(\w+)' => sub { 
                my $args = shift;
                is( $1 , 'c9s' );
                ok( $args->{name} );
                is( $args->{name} , 'amy' );
                return { timeline => [ 1 .. 10 ] };
            },
        ],
    }  );
    ok( $m , 'obj' );
    my $ret = $m->post->dispatch( '/foo/timeline/add/', { name => 'john' } );
    ok( $ret );
    is( $ret , 'ok' );

    $ret = $m->get->dispatch(  '/foo/timeline/get/c9s' , { name => 'amy' } );
    ok( $ret );
    is( ref($ret) , 'HASH' );

    $ret = $m->dispatch( '/foo/timeline/add/', { name => 'john' } );
    ok( $ret );
    is( $ret , 'ok' );
}


{
    my $m = Web::API::Mapper->new->mount( "/foo" => {
        post => [
            '/timeline/add/' => sub {
                my $args = shift;
                ok( $args->{name} , 'got name' );
                return "ok";
            },
        ],
        get => [
            '/timeline/get/(\w+)' => sub { 
                my $args = shift;
                is( $1 , 'c9s' );
                ok( $args->{name} );
                is( $args->{name} , 'amy' );
                return { timeline => [ 1 .. 10 ] };
            },
        ] })->mount( '/twitter' =>  { get => [ 
               '/timeline/(\w+)' => sub { ok($1); return $1; }
            ] } );

    ok( $m , 'obj' );
    my $ret = $m->post->dispatch( '/foo/timeline/add/', { name => 'john' } );
    ok( $ret );
    is( $ret , 'ok' );

    $ret = $m->get->dispatch(  '/foo/timeline/get/c9s' , { name => 'amy' } );
    ok( $ret );
    is( ref($ret) , 'HASH' );

    $ret = $m->dispatch( '/foo/timeline/add/', { name => 'john' } );
    ok( $ret );
    is( $ret , 'ok' );

    $ret = $m->dispatch( '/twitter/timeline/blah' );
    is( $ret , 'blah' );
}


