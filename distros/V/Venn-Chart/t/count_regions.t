#!/usr/bin/perl
#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2010
# Update    : 18/09/2010 14:23:35
# AIM       : Test count regions
#==================================================================
use strict;
use warnings;
use Carp;

use Test::More tests => 3;
use Venn::Chart;

my @list1 = map { int( rand(20) ) } ( 1 .. 20 );
my @list2 = map { int( rand(20) ) } ( 1 .. 20 );
my @list3 = map { int( rand(20) ) } ( 1 .. 20 );

my $VennChart = new Venn::Chart;
my $gd_venn   = $VennChart->plot( \@list1, \@list2, \@list3 );
my @regions   = $VennChart->get_regions;

my $number_list1 = doublon( \@list1 );
my $number_list2 = doublon( \@list2 );
my $number_list3 = doublon( \@list3 );

is( $number_list1, $regions[0] + $regions[2] + $regions[4] + $regions[6], 'list 1' );
is( $number_list2, $regions[1] + $regions[2] + $regions[5] + $regions[6], 'list 2' );
is( $number_list3, $regions[3] + $regions[4] + $regions[5] + $regions[6], 'list 3' );

sub doublon {
  my ($ref_array) = @_;

  my %temp;
  @temp{ @{$ref_array} } = ();
  return keys %temp;
}