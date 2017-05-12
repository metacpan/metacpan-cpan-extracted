#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 14;
use FindBin qw( $Bin );

use_ok "Test::Image";

my $red   = [255,0,0];
my $green = [0,255,0];
my $blue  = [0,0,255];
my $white = [255,255,255];
my $black = [0,0,0];

my $i = Test::Image->new("$Bin/test.png");
isa_ok($i, "Test::Image");

$i->size( 9, 9 );
$i->pixel(0, 0, $white);
$i->pixel(1, 1, $black);
$i->pixel(2, 2, $black);
$i->pixel(3, 3, $blue);
$i->pixel(4, 4, $blue);
$i->pixel(5, 5, $blue);
$i->pixel(6, 6, $black);
$i->pixel(7, 7, $black);
$i->pixel(8, 8, $white);

$i->row(0, $white);
$i->row(8, $white);

