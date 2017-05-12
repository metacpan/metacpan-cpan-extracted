#!perl

# checking WWW::FMyLife::Item

use strict;
use warnings;
use WWW::FMyLife;

use Test::More tests => 1;

my $fml  = WWW::FMyLife->new();
my $item = WWW::FMyLife::Item->new(
    author   => { content => 'name' },
    category => 'love',
    text     => 'hello world',
);

isa_ok( $item, 'WWW::FMyLife::Item' );

