#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::RectSet;

use Tickit::Rect;

# Distinct regions
{
   my $rectset = Tickit::RectSet->new;

   ok( defined $rectset, '$rectset defined' );
   isa_ok( $rectset, "Tickit::RectSet", '$rectset isa Tickit::RectSet' );

   is( scalar $rectset->rects, 0, '$rectset initially empty' );

   $rectset->add( Tickit::Rect->new( top => 10, left => 10, lines => 5, cols => 20 ) );

   is_deeply( [ $rectset->rects ],
              [ Tickit::Rect->new( top => 10, left => 10, lines => 5, cols => 20 ) ],
              '$rectset contains 1 rect after first add' );

   $rectset->add( Tickit::Rect->new( top => 20, left => 10, lines => 2, cols => 20 ) );

   is_deeply( [ $rectset->rects ],
              [ Tickit::Rect->new( top => 10, left => 10, lines => 5, cols => 20 ),
                Tickit::Rect->new( top => 20, left => 10, lines => 2, cols => 20 ) ],
              '$rectset contains 2 rects after second add' );

   $rectset->clear;

   is( scalar $rectset->rects, 0, '$rectset empty after ->clear' );
}

# Intersect and containment tests
{
   my $rectset = Tickit::RectSet->new;
   $rectset->add( Tickit::Rect->new( top => 1, left => 1, bottom => 5, right => 20 ) );
   $rectset->add( Tickit::Rect->new( top => 5, left => 1, bottom => 10, right => 10 ) );

   ok(  $rectset->intersects( Tickit::Rect->new( top => 0, left => 0, bottom => 5, right => 5 ) ), '$rectset intersects overlap' );
   ok( !$rectset->intersects( Tickit::Rect->new( top => 6, left => 15, bottom => 9, right => 25 ) ), '$rectset no intersect' );

   ok(  $rectset->contains( Tickit::Rect->new( top => 1, left => 5, bottom => 4, right => 15 ) ), '$rectset contains simple' );
   ok(  $rectset->contains( Tickit::Rect->new( top => 2, left => 5, bottom => 9, right => 8 ) ), '$rectset contains split' );
   ok( !$rectset->contains( Tickit::Rect->new( top => 2, left => 5, bottom => 9, right => 12 ) ), '$rectset no contains split' );
   ok( !$rectset->contains( Tickit::Rect->new( top => 6, left => 15, bottom => 9, right => 25 ) ), '$rectset no contains non-intersect' );
}

sub _newrect
{
   local $_ = shift;

   m/^(\d+),(\d+)\+(\d+)x(\d+)$/ and return
      Tickit::Rect->new( left => $1, top => $2, cols => $3, lines => $4 );

   m/^(\d+),(\d+)\.\.(\d+),(\d+)$/ and return
      Tickit::Rect->new( left => $1, top => $2, right => $3, bottom => $4 );

   die "Unrecognised rectangle spec $_\n";
}

my $name;
while( <DATA> ) {
   next if m/^\s*$/;
   $name = $1, next if m/^\s*#\s*(.*)$/;

   my ( $input, $output ) = m/^(.*)\s*=>\s*(.*)$/ or die "Expected =>\n";
   my @input = split m/\s+/, $input;
   my $method = shift @input;
   my @inputrects  = map _newrect($_), @input;
   my @outputrects = map _newrect($_), split m/\s+/, $output;

   if( $method eq "add" ) {
      my $rectset = Tickit::RectSet->new;
      $rectset->add( $_ ) for @inputrects;

      is_deeply( [ $rectset->rects ], \@outputrects, "Output for $name $input" );

      $rectset = Tickit::RectSet->new;
      $rectset->add( $_ ) for reverse @inputrects;

      is_deeply( [ $rectset->rects ], \@outputrects, "Output for $name $input reversed" );
   }
   if( $method eq "subtract" ) {
      my $rectset = Tickit::RectSet->new;
      $rectset->add( shift @inputrects );
      $rectset->subtract( $_ ) for @inputrects;

      is_deeply( [ $rectset->rects ], \@outputrects, "Output for $name $input" );
   }
}

done_testing;

__DATA__

# Distinct regions
add 10,10..30,15 40,10..60,15 => 10,10..30,15 40,10..60,15
add 10,10..30,15 10,20..30,25 => 10,10..30,15 10,20..30,25

# Ignorable regions
add 10,10..30,15 10,10..30,15 => 10,10..30,15
add 10,10..30,15 10,10..20,12 => 10,10..30,15
add 10,10..30,15 20,13..30,15 => 10,10..30,15
add 10,10..30,15 15,11..25,14 => 10,10..30,15

# Overlapping extension top
add 10,10..30,15 10,8..30,12 => 10,8..30,15
add 10,10..30,15 10,8..30,10 => 10,8..30,15
add 10,10..30,12 10,15..30,17 10,12..30,15 => 10,10..30,17

# Overlapping extension bottom
add 10,10..30,15 10,12..30,17 => 10,10..30,17
add 10,10..30,15 10,15..30,17 => 10,10..30,17

# Overlapping extension left
add 10,10..30,15 5,10..25,15 => 5,10..30,15
add 10,10..30,15 5,10..10,15 => 5,10..30,15

# Overlapping extension right
add 10,10..30,15 20,10..35,15 => 10,10..35,15
add 10,10..30,15 30,10..35,15 => 10,10..35,15

# L/T shape top abutting
add 10,10..30,15 10,8..20,10 => 10,8..20,10 10,10..30,15
add 10,10..30,15 15,8..25,10 => 15,8..25,10 10,10..30,15
add 10,10..30,15 20,8..30,10 => 20,8..30,10 10,10..30,15

# L/T shape top overlapping
add 10,10..30,15 10,8..20,12 => 10,8..20,10 10,10..30,15
add 10,10..30,15 15,8..25,12 => 15,8..25,10 10,10..30,15
add 10,10..30,15 20,8..30,12 => 20,8..30,10 10,10..30,15

# L/T shape bottom abutting
add 10,10..30,15 10,15..20,17 => 10,10..30,15 10,15..20,17
add 10,10..30,15 15,15..25,17 => 10,10..30,15 15,15..25,17
add 10,10..30,15 20,15..30,17 => 10,10..30,15 20,15..30,17

# L/T shape bottom overlapping
add 10,10..30,15 10,13..20,17 => 10,10..30,15 10,15..20,17
add 10,10..30,15 15,13..25,17 => 10,10..30,15 15,15..25,17
add 10,10..30,15 20,13..30,17 => 10,10..30,15 20,15..30,17

# L/T shape left abutting
add 10,10..30,15 5,10..10,12 => 5,10..30,12 10,12..30,15
add 10,10..30,15 5,11..10,14 => 10,10..30,11 5,11..30,14 10,14..30,15
add 10,10..30,15 5,13..10,15 => 10,10..30,13 5,13..30,15

# L/T shape left overlapping
add 10,10..30,15 5,10..15,12 => 5,10..30,12 10,12..30,15
add 10,10..30,15 5,11..15,14 => 10,10..30,11 5,11..30,14 10,14..30,15
add 10,10..30,15 5,13..15,15 => 10,10..30,13 5,13..30,15

# L/T shape right abutting
add 10,10..30,15 30,10..35,12 => 10,10..35,12 10,12..30,15
add 10,10..30,15 30,11..35,14 => 10,10..30,11 10,11..35,14 10,14..30,15
add 10,10..30,15 30,13..35,15 => 10,10..30,13 10,13..35,15

# L/T shape right overlapping
add 10,10..30,15 20,10..35,12 => 10,10..35,12 10,12..30,15
add 10,10..30,15 20,11..35,14 => 10,10..30,11 10,11..35,14 10,14..30,15
add 10,10..30,15 20,13..35,15 => 10,10..30,13 10,13..35,15

# Cross shape
add 10,10..30,15 15,5..25,20 => 15,5..25,10 10,10..30,15 15,15..25,20

# Diagonal overlap
add 10,10..30,15 20,12..40,20 => 10,10..30,12 10,12..40,15 20,15..40,20
add 10,10..30,15  0,12..20,20 => 10,10..30,12  0,12..30,15  0,15..20,20


# Distinct regions
subtract 10,10..30,15 10,20..30,22 => 10,10..30,15

# Overlapping truncate left
subtract 10,10..30,15 5,10..20,15 => 20,10..30,15

# Overlapping truncate right
subtract 10,10..30,15 20,10..35,15 => 10,10..20,15

# Overlapping truncate top
subtract 10,10..30,15 10,8..30,12 => 10,12..30,15

# Overlapping truncate bottom
subtract 10,10..30,15 10,13..30,18 => 10,10..30,13

# Overlapping U left
subtract 10,10..30,15 5,11..20,14 => 10,10..30,11 20,11..30,14 10,14..30,15

# Overlapping U right
subtract 10,10..30,15 20,11..35,14 => 10,10..30,11 10,11..20,14 10,14..30,15

# Overlapping U top
subtract 10,10..30,15 15,8..25,12 => 10,10..15,12 25,10..30,12 10,12..30,15

# Overlapping U bottom
subtract 10,10..30,15 15,13..25,18 => 10,10..30,13 10,13..15,15 25,13..30,15

# Remove entirely
subtract 10,10..30,15 8,8..32,17 =>
