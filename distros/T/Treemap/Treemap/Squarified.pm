package Treemap::Squarified;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require Treemap;

our @ISA = qw(Treemap Exporter);
our @EXPORT_OK = (  );
our @EXPORT = qw( );
our $VERSION = '0.02';


# ------------------------------------------
# Methods:
# ------------------------------------------

#
# Input: a tree of array-hashes
# Output: none, sent to callbacks
#
sub _map
{
   my $self = shift;
   my ( @p, @q, $tree );
   my $debug = undef;
   ( $tree, $p[0], $p[1], $q[0], $q[1] ) = @_;

   $self->{DEBUG} && print STDERR "Drawing space for $tree->{name}:\n\t@p, @q\n";

   # Draw our rectangle
   $self->{ OUTPUT }->rect( $p[0], $p[1], $q[0], $q[1], $tree->{colour} );

   # Non-empty Set, Descend
   if( $tree->{children} )
   {
      my ( $pt, $qt ) = $self->_shrink( \@p, \@q, $self->{PADDING} );
      my @p = @{$pt}; my @q = @{$qt};

      $self->{DEBUG} && print STDERR "\tI have " . scalar( @{$tree->{children}} ) . " children... ";

      # Check number of children 
      # If < 3, two slices on the longest side is optimal aspect ratio
      if( scalar(@{$tree->{children}}) < 3 )
      {
         $self->{DEBUG} && print STDERR "SLICE.\n";

         my ( @r, @s, $o, $width );
         $o = ( abs($p[0]-$q[0]) > abs($p[1]-$q[1]) ? 0 : 1 );
         @r = @p;
         @s = @q;
         $width = abs( $s[$o] - $r[$o] );
         foreach my $child( @{$tree->{children}} )
         {
            $s[$o] = $r[$o] + $width * 
               ( $child->{size} / $tree->{size} ) if( $tree->{size} > 0 ); 
            {
               my ( $st, $rt ) = $self->_shrink( \@s, \@r, $self->{SPACING} );
               my @s = @{$st}; my @r = @{$rt};
               $self->_map( $child, $r[0], $r[1], $s[0], $s[1] );
            }
            $r[$o] = $s[$o];
         }
      }
      # Otherwise, find optimal aspect ratio
      else
      {
         $self->{DEBUG} && print STDERR "SQUARIFY.\n";

         # Sort children by size, descending
         my @indices = 0..( scalar( @{$tree->{children}} ) - 1 );
         my @sorted_children = sort { $tree->{children}->[$b]->{size} <=> 
                                      $tree->{children}->[$a]->{size} }
                                    @indices;

         # Fetch each entry and compute the aspect ratio when their areas are
         # combined.
         #
         # height (h), and area (a) are our "fixed" values, and width (w) will
         # change based on the current 'a'.
         #
         # So:
         #  a = h*w
         #  w = a/h
         #
         # And:
         #  aspect = w/h
         #
         # Therefore:
         #  aspect = (a/h)/h
         #         = a / h**2
         #

         my ( $area, $parent_area, $parent_aspect, $usable_width, $usable_height, @j, @k, $o );
         $area = 0;
         $parent_area = $tree->{size};
         @j = @p;
         @k = @q;
         $o = ( abs($j[0]-$k[0]) > abs($j[1]-$k[1]) ? 0 : 1 );
         $usable_width = 0;

         # Only run if these children consume space, and we indeed have children
         while( $parent_area > 0 && @sorted_children > 0 )
         {
            # Remove area that was consumed by 'special children' (see below)
            $parent_area -= $area;

            # Reset consumed area
            $area = 0;

            # Determine new boundary
            $j[$o] = $j[$o] + $usable_width;

            # Exit loop we've run out of pixel drawing space (prevents division
            # by zero errors in aspect ratio calculations)
            last if ( $j[0] == $k[0] || $j[1] == $k[1] );

            # Determine new orientation based on new boundary
            $o = ( abs($j[0]-$k[0]) > abs($j[1]-$k[1]) ? 0 : 1 );

            # Determine new parent aspect ratio based on new boundary
            $parent_aspect = (
               abs( $j[$o] - $k[$o] ) / 
               abs( $j[($o xor 1)] - $k[($o xor 1)] )
            );

            # Determine new scaled height based on new aspect and available area
            my $scaled_height = sqrt( $parent_area / $parent_aspect );

            # Reset special children to nothing
            my @special_children;

            # Reset apsect ratio
            my $aspect = 0;

            while( scalar( @sorted_children ) > 0 )
            {
               my $child = shift( @sorted_children );
               push( @special_children, $child );
               my $area_test = $area + $tree->{children}->[$child]->{size};

               # Find worst aspect ratio in this set of special children
               my $aspect_test = $self->_find_worst( $tree->{children}, \@special_children, $area_test, $scaled_height );

               # If this aspect ratio is better than the last, keep searching
               if( $aspect_test > $aspect )
               {

                  $self->{DEBUG} && print STDERR "\t\t$aspect_test is a BETTER aspect ratio than $aspect\n";

                  # getting warmer, keep searching
                  $area = $area_test;
                  $aspect = $aspect_test;
               }
               else
               {

                  $self->{DEBUG} && print STDERR "\t\t$aspect_test is a WORSE aspect ratio than $aspect\n";

                  # nope, last set was better, undo this scenario.
                  pop( @special_children );
                  unshift( @sorted_children, $child );
                  # last set was the optimum set for this space, so drop out of
                  # the loop and handle these special children
                  last;
               }
            }

            # Handle special children
            if( @special_children > 0 )
            {

               $self->{DEBUG} && print STDERR "\t\t\tHandling Special Children: @special_children\n";

               my ( @r, @s );
               my $o_xor = ( $o xor 1 );
               # Amount of width these children are allowed to consume from parent space
               $usable_width = ($k[$o]-$j[$o]) * ( $area / $parent_area );
               # Amount of height these children are allowed to consume from
               # parent space (all in this case)
               $usable_height = $k[$o_xor] - $j[$o_xor];

               @r = @j;
               @s = @k;
               $s[$o] = $r[$o] + $usable_width;

               $self->{DEBUG} && print STDERR "\t\t\tUsable Space for Special Children: $usable_width x $usable_height\n";
               
               # Each child gets a slice of the available height
               foreach my $child( @special_children )
               {
                  $s[$o_xor] = $r[$o_xor] + $usable_height * 
                     ( $tree->{children}->[$child]->{size} / $area )
                        if( $area > 0 );
                  { 
                     my ( $st, $rt ) = $self->_shrink( \@s, \@r, $self->{SPACING} );
                     my @s = @{$st}; my @r = @{$rt};
                     $self->_map( $tree->{children}->[$child], 
                              $r[0], $r[1], $s[0], $s[1] 
                            );
                  }
                  $r[$o_xor] = $s[$o_xor];
               }
            }
            else
            {
               $self->{DEBUG} && print STDERR "No special children... awww\n";
            }
            # Continue processing remaining children at top of loop
         }
      }
   }
   # Draw label
   $self->{ OUTPUT }->text( $p[0], $p[1], $q[0], $q[1], $tree->{name}, ($tree->{children}?1:undef) );
}

# Expects the 'height' of the area we're filling
# No side-effects.
#WARNING WARNING WARNING
#WARNING WARNING WARNING
#
# Hey you already know the area from the parent, why are you re-calculating it?
# Change the expected format to be treemap data, rather than an array
#
#WARNING WARNING WARNING
#WARNING WARNING WARNING
#WARNING WARNING WARNING
sub _find_worst
{
   my $self = shift;
   my ( $tree, $set, $area, $height ) = @_;

   # Find width
   my $width = $area / $height;
   my $width_squared = $width ** 2;

#IDEAIDEA
#
# We could optionally determine the average aspect ratio, and use that for
# comparison to other sets
#
#IDEAIDEA
   # Find worst aspect ratio
   my $worst = undef;
   foreach my $item( @{$set} )
   {
      # for our purposes, apsect = w/h, where w>h, but we'll take the inverse
      # if it exeeds 1
      #
      # aspect = w/h; area = w*h, h = area/w
      # aspect = w/(area/w)
      #        = w^2/area
      #

      # An item with a size/area of 0 is the worst possible thing. It's aspect
      # ratio is infinite, which is ... the worst you could wish for ;)
      return 0 if $tree->[$item]->{size} == 0;

      my $aspect = $width_squared / $tree->[$item]->{size};

      # if an aspect ratio is > 1, we take the inverse
      $aspect = 1 / $aspect if ( $aspect > 1 );    

      if ( $worst )
      {
         $worst = $aspect if ( $aspect < $worst );
      }
      else
      {
         $worst = $aspect;
      }
   }
   return $worst;
}

1;
__END__

=head1 NAME 

Treemap::Squarified - Make a Treemap, using the squarified treemap algorithm.

=head1 METHODS

See METHODS section of L<Treemap>.

=head1 THEORY OF OPERATION

First, we sort the list of nodes at our current depth based on their area (or
size), in descending order.

We then take the first node and find the aspect ratio for it's required area,
then compare that to the aspect ratio of the first and second node added
together, and so on, until the aspect ratio become non-ideal (when it exceeds
one).

e.g.

The aspect ratio, W/H, in this case is < 1, so we would like to maximize our
width 'X' to 'W' for area 'A', and then expand the height 'Y', until our area
'A' has the aspect ratio closest to 1.

     <---- W ---->     Calculating the Aspect ratio:

 ^   +-----------+     We know the value of A, and W
 |   |+---------+|     We also know that X = W
 |   ||         ||     
 |   ||    A    Y|     Therefore:  
 |   ||         ||           A = XY
 H   |+----X----+|           A = WY
 |   |           |           Y = A/W
 |   |           |
 |   |           |      Aspect = Width / Height
 V   +-----------+      Aspect = W / ( A / W )        
                        Aspect = W^2 / A

We would calculate the 'Aspect Ratio' of Node1 with area A1, and compare it to
the 'Aspect Ratio' of Node 1 and Node 2, with area (A1+A2). Further nodes are
added, until the aspect ratio becomes non-ideal.

If we were to plot the 'Aspect Ratio' as 'Y' was increased, we would get:

 Aspect
   |        ./
 1 |      ./ 
   |    ./  
   |  ./   
   |./    
   +---------- Y
 0        

If instead we take the inverse of the 'Aspect Ratio' when it is greater than one,
we would get:

 Aspect
 1 |    
   |   /\     
   |  /  \  
   | /    \
   |/      \
   +---------- Y
 0        

This makes it easier to compare two aspect ratios when they span the perfect
aspect ratio of 1.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Treemap>

=head1 BUGS

The aspect ratios don't come out ideal when there is a large difference in
size between objects at the same level. It might perform better if there was a
'look ahead' to see if the item currently being tested would fit better in the
space being tested, or in the space that's left over.

=head1 AUTHORS

Simon P. Ditner <simon@uc.org>, and Eric Maki <eric@uc.org>

=head1 CREDITS

Original Treemap Concept: Ben Shneiderman <ben@cs.umd.edu>,
http://www.cs.umd.edu/hcil/treemap-history/index.shtml

Squarified Treemap Concept: Visualization Group of the Technische Universiteit
Eindhoven

=head1 COPYRIGHT

(c)2003

=cut
