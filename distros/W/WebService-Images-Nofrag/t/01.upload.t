#!/usr/bin/perl -w

use strict;
use Test::More tests => 11;
use WebService::Images::Nofrag;

use_ok( 'WebService::Images::Nofrag' );

can_ok( 'WebService::Images::Nofrag', 'upload' );

my $pix = WebService::Images::Nofrag->new();
$pix->upload( { file => "t/cpan-10.jpg" } );

is( $pix->url,
    "http://pix.nofrag.com/81/d4/16b8d695301ffeef2a24af2cdc7a.html",
    "url to the page" );
is( $pix->image,
    "http://pix.nofrag.com/81/d4/16b8d695301ffeef2a24af2cdc7a.jpg",
    "url to the image" );
is( $pix->thumb,
    "http://pix.nofrag.com/81/d4/16b8d695301ffeef2a24af2cdc7at.jpg",
    "url to the thumbnail" );

my $spix = WebService::Images::Nofrag->new();
$spix->upload( { file => "t/cpan-10.jpg", resize => "20%" } );

is( $spix->url,
    "http://pix.nofrag.com/29/df/5d3c69d7457fe61b5a0e367b22d8.html",
    "url to the page" );
is( $spix->image,
    "http://pix.nofrag.com/29/df/5d3c69d7457fe61b5a0e367b22d8.jpg",
    "url to the image" );
is( $spix->thumb,
    "http://pix.nofrag.com/29/df/5d3c69d7457fe61b5a0e367b22d8.jpg",
    "url to the thumbnail" );

my $upix = WebService::Images::Nofrag->new();
$upix->upload( { url    => "http://search.cpan.org/s/img/cpan_banner.png",
                 resize => "80%"
               } );
is( $upix->url,
    "http://pix.nofrag.com/ad/1b/2c18a3895c31242e06255ecea47f.html",
    "url to the page" );
is( $upix->image,
    "http://pix.nofrag.com/ad/1b/2c18a3895c31242e06255ecea47f.jpeg",
    "url to the image" );
is( $upix->thumb,
    "http://pix.nofrag.com/ad/1b/2c18a3895c31242e06255ecea47ft.jpg",
    "url to the thumbnail" );
