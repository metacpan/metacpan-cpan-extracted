#!/usr/bin/perl

use warnings;
use strict;

use Test::LectroTest;

=head1 NAME

t/docs-eg.t - test cases for examples from documentation

=head1 SYNOPSIS

  perl -Ilib t/docs-eg.t

=head1 DESCRIPTION

These test cases make sure that the examples in the documentation work.

=head2 Examples from Property.pm

=cut

sub my_sqrt { sqrt($_[0]) }

my $epsilon = 0.000_001;

Property {
      ##[ x <- Float ]##
      return $tcon->retry if $x < 0;
      $tcon->label("less than 1") if $x < 1;
      my $sx = my_sqrt( $x );
      abs($sx * $sx - $x) < $epsilon;
}, name => "my_sqrt satisfies defn of square root";

sub my_thing_to_test { 1 }

Property {
    ##[ i <- Int, delta <- Float(range=>[0,1]) ]##
    my $lo_val = my_thing_to_test($i);
    my $hi_val = my_thing_to_test($i + $delta);
    1;
}, name => "my_thing_to_test ignores fractions" ;

{
  my $prop = Test::LectroTest::Property->new(
    inputs => [ i => Int, delta => Float(range=>[0,1]) ],
    test => sub {
        my ($tcon, $delta, $i) = @_;
        my $lo_val = my_thing_to_test($i);
        my $hi_val = my_thing_to_test($i + $delta);
    },
    name => "my_thing_to_test ignores fractions"
  ) ;
  push @Test::LectroTest::props, $prop;
} 

