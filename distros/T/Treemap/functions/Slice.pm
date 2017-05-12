#!/usr/bin/perl -w

use strict;
use Data::Dumper;

# Test Data
my $sample_data;
$sample_data->{name} = "root";
$sample_data->{size} = 12;
$sample_data->{colour} = "#FFFFFF";
$sample_data->{children}->[0]->{name} = "one";
$sample_data->{children}->[0]->{size} = 4;
$sample_data->{children}->[0]->{colour} = "#FFFFFF";
$sample_data->{children}->[1]->{name} = "two";
$sample_data->{children}->[1]->{size} = 3;
$sample_data->{children}->[1]->{colour} = "#FFFFFF";
$sample_data->{children}->[1]->{children}->[0]->{name} = "red";
$sample_data->{children}->[1]->{children}->[0]->{size} = 1;
$sample_data->{children}->[1]->{children}->[0]->{colour} = "#FFFFFF";
$sample_data->{children}->[1]->{children}->[1]->{name} = "green";
$sample_data->{children}->[1]->{children}->[1]->{size} = 2;
$sample_data->{children}->[1]->{children}->[1]->{colour} = "#FFFFFF";
$sample_data->{children}->[2]->{name} = "three";
$sample_data->{children}->[2]->{size} = 5;
$sample_data->{children}->[2]->{colour} = "#FFFFFF";


# Test "draw" functions
my $rect = \&rect;
my $text = \&text;
my $debug_depth = 0;
sub rect 
{
   print " " x ($debug_depth*3);
   print "rect: @_\n";
}

sub text
{
   print " " x ($debug_depth*3);
   print "text: @_\n";
}


#print Dumper($sample_data);
&render( $sample_data, 0, 0, 1023, 767 );

#
# Input: a tree of array-hashes
# Output: none
#
sub render
{
   my ( @p, @q, $tree, $o );
   ( $tree, $p[0], $p[1], $q[0], $q[1], $o ) = @_;
   $o = $o || 0;  # Orientation of our slicing

   # Draw our rectangle
   &{$rect}( $p[0], $p[1], $q[0], $q[1], $tree->{colour} );

   # Non-empty Set, Descend
   if( $tree->{children} )
   {
      my @r = @p;
      my @s = @q;
      my $width = abs($p[$o] - $q[$o]);
      my $size = $tree->{size};

      # Process each child
      foreach my $child( @{$tree->{children}} )
      {
         # Give this child a percentage of the parent's space, based on
         # parent's size (make sure we don't cause divide by zero errors)
         $s[$o] = $r[$o] + $width * ( $child->{size} / $size ) if ( $size > 0 );

         # Rotate the space by 90 degrees, by xor'ing the 'o'rientation
         &render( $child, $r[0], $r[1], $s[0], $s[1], ($o xor 1) );
         $r[$o] = $s[$o];
      }
   }
   # Draw label
   &{$text}( $tree->{name} );
}

