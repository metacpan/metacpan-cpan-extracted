#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Rect;

my $rect = Tickit::Rect->new(
   top  => 5,
   left => 10,
   lines => 7,
   cols  => 20,
);

isa_ok( $rect, "Tickit::Rect", '$rect' );

is( $rect->top,     5, '$rect->top' );
is( $rect->left,   10, '$rect->left' );
is( $rect->lines,   7, '$rect->lines' );
is( $rect->cols,   20, '$rect->cols' );
is( $rect->bottom, 12, '$rect->bottom' );
is( $rect->right,  30, '$rect->right' );

is_deeply( [ $rect->linerange ], [ 5 .. 11 ], '$rect->linerange' );
is_deeply( [ $rect->linerange( 8, undef ) ], [ 8 .. 11 ], '$rect->linerange with min bound' );
is_deeply( [ $rect->linerange( undef, 9 ) ], [ 5 .. 9 ], '$rect->linerange with max bound' );
is_deeply( [ $rect->linerange( 2, 20 ) ], [ 5 .. 11 ], '$rect->linerange with bounds outside' );

my $subrect;

$subrect = $rect->intersect( Tickit::Rect->new( top => 0, left => 0, lines => 25, cols => 80 ) );
is( $subrect->top,     5, '$subrect->top after intersect wholescreen' );
is( $subrect->left,   10, '$subrect->left after intersect wholescreen' );
is( $subrect->lines,   7, '$subrect->lines after intersect wholescreen' );
is( $subrect->cols,   20, '$subrect->cols after intersect wholescreen' );
is( $subrect->bottom, 12, '$subrect->bottom after intersect wholescreen' );
is( $subrect->right,  30, '$subrect->right after intersect wholescreen' );

$subrect = $rect->intersect( Tickit::Rect->new( top => 10, left => 20, lines => 15, cols => 60 ) );
is( $subrect->top,    10, '$subrect->top after intersect partial' );
is( $subrect->left,   20, '$subrect->left after intersect partial' );
is( $subrect->lines,   2, '$subrect->lines after intersect partial' );
is( $subrect->cols,   10, '$subrect->cols after intersect partial' );
is( $subrect->bottom, 12, '$subrect->bottom after intersect partial' );
is( $subrect->right,  30, '$subrect->right after intersect partial' );

$subrect = $rect->intersect( Tickit::Rect->new( top => 20, left => 20, lines => 5, cols => 60 ) );
ok( !defined $subrect, '$subrect undefined after intersect outside' );

ok(  $rect->contains( Tickit::Rect->new( top => 7, left => 12, lines => 3, cols => 10 ) ), '$rect contains smaller rect' );
ok( !$rect->contains( Tickit::Rect->new( top => 3, left => 10, lines => 5, cols => 12 ) ), '$rect does not contain overlap' );

ok(  $rect->intersects( Tickit::Rect->new( top => 3, left => 10, lines => 5, cols => 12 ) ), '$rect intersects with overlap' );
ok( !$rect->intersects( Tickit::Rect->new( top => 14, left => 10, lines => 3, cols => 20 ) ), '$rect does not intersect with other' );
ok( !$rect->intersects( Tickit::Rect->new( top => 12, left => 10, lines => 3, cols => 20 ) ), '$rect does not intersect with abutting' );

# Extent constructor
{
   my $rect = Tickit::Rect->new(
      top    => 3,
      left   => 8,
      bottom => 9,
      right  => 22,
   );

   is( $rect->top,     3, '$rect->top' );
   is( $rect->left,    8, '$rect->left' );
   is( $rect->lines,   6, '$rect->lines' );
   is( $rect->cols,   14, '$rect->cols' );
   is( $rect->bottom,  9, '$rect->bottom' );
   is( $rect->right,  22, '$rect->right' );
}

# String constructor
{
   my $rect = Tickit::Rect->new( "(3,5)..(8,12)" );

   is( $rect->top,     5, '$rect->top from string constructor' );
   is( $rect->left,    3, '$rect->left from string constructor' );
   is( $rect->bottom, 12, '$rect->bottom from string constructor' );
   is( $rect->right,   8, '$rect->right from string constructor' );
}

# Rectangle addition
{
   my $r = Tickit::Rect->new( "(10,10)..(20,20)" );

   is_deeply( [ $r->add( Tickit::Rect->new( "(10,10)..(20,20)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,20)" ) ],
              '$r->add same' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(5,10)..(10,20)" ) ) ],
              [ Tickit::Rect->new( "(5,10)..(20,20)" ) ],
              '$r->add left' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(20,10)..(25,20)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(25,20)" ) ],
              '$r->add right' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(10,5)..(20,10)" ) ) ],
              [ Tickit::Rect->new( "(10,5)..(20,20)" ) ],
              '$r->add top' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(10,20)..(20,25)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,25)" ) ],
              '$r->add bottom' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(12,20)..(18,30)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,20)" ),
                Tickit::Rect->new( "(12,20)..(18,30)" ) ],
              '$r->add T below' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(0,12)..(10,18)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,12)" ),
                Tickit::Rect->new( "(0,12)..(20,18)" ),
                Tickit::Rect->new( "(10,18)..(20,20)" ) ],
              '$r->add T left' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(15,15)..(25,25)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,15)" ),
                Tickit::Rect->new( "(10,15)..(25,20)" ),
                Tickit::Rect->new( "(15,20)..(25,25)" ) ],
              '$r->add diagonal' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(12,8)..(18,22)" ) ) ],
              [ Tickit::Rect->new( "(12,8)..(18,10)" ),
                Tickit::Rect->new( "(10,10)..(20,20)" ),
                Tickit::Rect->new( "(12,20)..(18,22)" ) ],
              '$r->add cross' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(10,30)..(20,40)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,20)" ),
                Tickit::Rect->new( "(10,30)..(20,40)" ) ],
              '$r->add non-overlap horizontal' );

   is_deeply( [ $r->add( Tickit::Rect->new( "(30,10)..(40,20)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,20)" ),
                Tickit::Rect->new( "(30,10)..(40,20)" ) ],
              '$r->add non-overlap horizontal' );
}

# Rectangle subtraction
{
   my $r = Tickit::Rect->new( "(10,10)..(20,20)" );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(10,10)..(20,20)" ) ) ],
              [],
              '$r->subtract same' );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(5,10)..(15,20)" ) ) ],
              [ Tickit::Rect->new( "(15,10)..(20,20)" ) ],
              '$r->subtract truncate left' );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(15,10)..(25,20)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(15,20)" ) ],
              '$r->subtract truncate right' );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(10,5)..(20,15)" ) ) ],
              [ Tickit::Rect->new( "(10,15)..(20,20)" ) ],
              '$r->subtract truncate top' );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(10,15)..(20,25)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,15)" ) ],
              '$r->subtract truncate bottom' );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(5,12)..(15,18)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,12)" ),
                Tickit::Rect->new( "(15,12)..(20,18)" ),
                Tickit::Rect->new( "(10,18)..(20,20)" ) ],
              '$r->subtract U left' );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(15,12)..(25,18)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,12)" ),
                Tickit::Rect->new( "(10,12)..(15,18)" ),
                Tickit::Rect->new( "(10,18)..(20,20)" ) ],
              '$r->subtract U right' );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(12,5)..(18,15)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(12,15)" ),
                Tickit::Rect->new( "(18,10)..(20,15)" ),
                Tickit::Rect->new( "(10,15)..(20,20)" ) ],
              '$r->subtract U top' );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(12,15)..(18,25)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,15)" ),
                Tickit::Rect->new( "(10,15)..(12,20)" ),
                Tickit::Rect->new( "(18,15)..(20,20)" ) ],
              '$r->subtract U bottom' );

   is_deeply( [ $r->subtract( Tickit::Rect->new( "(12,12)..(18,18)" ) ) ],
              [ Tickit::Rect->new( "(10,10)..(20,12)" ),
                Tickit::Rect->new( "(10,12)..(12,18)" ),
                Tickit::Rect->new( "(18,12)..(20,18)" ),
                Tickit::Rect->new( "(10,18)..(20,20)" ) ],
              '$r->subtract hole' );
}

done_testing;
