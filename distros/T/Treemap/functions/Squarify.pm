#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Imager;

require "Dir.pl";
#
#  Squarified Layout Flow Diagram:
#  ------------------------------
#
#             +------------+
#             | check list |
#             | length     |
#             +------------+
#               >2 |   | <= 2   +-----------+
#                  |   `------->| use slice |
#                  |            | layout    |
#                  V            +-----------+
#            +-----------+
#            | sort list | set area = 0
#  .-------->| by size   | set previous aspect ratio = 0
#  |         +-----------+
#  |               |
#  |               V
#  |           +-------+       +----------------+
#  |           | get   |------>| add entry size |
#  |  .------->| entry |       | to area        |
#  |  |        +-------+       +----------------+
#  |  |                               |
#  |  |                               V
#  |  |  +-----------------+   +--------------+
#  |  |  | compare current |<--| calc current |
#  |  |  | to previous     |   | aspect ratio |
#  |  |  +-----------------+   +--------------+
#  |  |        |     |
#  |  | better |     | worse   +-------------------+
#  |  `--------'     `-------->| stop, split list  |
#  |                           | at previous entry |
#  |                           +-------------------+
#  |                                     |
#  |          +---------------------+    |
#  |          | use slice layout on |<---'
#  |          | first part of list  |----.
#  |          +---------------------+    |
#  |                                     V
#  |                          +----------------------+
#  |                          | pass second half and |
#  `--------------------------| unsused layout space |
#                             | back to beginning    |
#                             +----------------------+
#


# Test Data
my $sample_data;
$sample_data->{name} = "root";
$sample_data->{size} = 12;
$sample_data->{colour} = 0xFF0000;
$sample_data->{children}->[0]->{name} = "one";
$sample_data->{children}->[0]->{size} = 4;
$sample_data->{children}->[0]->{colour} = 0xFF0F0F;
$sample_data->{children}->[1]->{name} = "two";
$sample_data->{children}->[1]->{size} = 3;
$sample_data->{children}->[1]->{colour} = 0x00FFFF;
$sample_data->{children}->[1]->{children}->[0]->{name} = "red";
$sample_data->{children}->[1]->{children}->[0]->{size} = 1;
$sample_data->{children}->[1]->{children}->[0]->{colour} = 0x0F00FF;
$sample_data->{children}->[1]->{children}->[1]->{name} = "green";
$sample_data->{children}->[1]->{children}->[1]->{size} = 2;
$sample_data->{children}->[1]->{children}->[1]->{colour} = 0x0FFF00;
$sample_data->{children}->[2]->{name} = "three";
$sample_data->{children}->[2]->{size} = 5;
$sample_data->{children}->[2]->{colour} = 0xFF00FF;

$sample_data = Dir2Tree( "../" );
my $image = Imager->new( xsize=>1024, ysize=>768 );
my $font_file = "/usr/X11R6/lib/X11/fonts/TTF/luxisr.ttf";

# Test "draw" functions
my $rect = \&rect;
my $text = \&text;
my $debug_depth = 0;
sub rect 
{
   my ( $x1, $y1, $x2, $y2, $colour ) = @_;

   print STDERR " " x ($debug_depth*3);
   print STDERR "rect: @_\n";
   my $RR = ( $colour >> 16 ) & 255;
   my $GG = ( $colour >> 8 ) & 255;
   my $BB = ( $colour ) & 255;
   my $my_colour = Imager::Color->new( $RR, $GG, $BB );
   my $black = Imager::Color->new( 0, 0, 0 );
   $image->box( color=>$my_colour, xmin=>$x1, ymin=>$y1, xmax=>$x2, ymax=>$y2, filled=>1 );
   $image->box( color=>$black, xmin=>$x1, ymin=>$y1, xmax=>$x2, ymax=>$y2, filled=>0 );
   return;
}

sub text
{
   my ( $x1, $y1, $x2, $y2, $text ) = @_;
   my $font =  Imager::Font->new( file=>$font_file, color=>Imager::Color->new( 0,0,0,50 ), aa=>1, type=>'ft2' );

   my $x = $x1 + ( $x2 - $x1 ) / 2;
   my $y = $y1 + ( $y2 - $y1 ) / 2;

   my $width = abs( $x2 - $x1 );
   my $height = abs( $y2 - $y1 );
# Search for suitable font size
   my $size;
   for ( $size=512; $size > 0; $size-- )
   {
      my @metrix = $font->bounding_box( string=>$text, size=>$size, canon=>1 );
      my $m_width = $metrix[2];
      my $m_height = $metrix[3];
      last if ( $m_width < $width && $m_height < $height );
   }
   $size = int( $size * 0.9 );
   my @metrix = $font->bounding_box( string=>$text, size=>$size, canon=>1 );
   $x -= $metrix[2]/2;
   $y += $metrix[3]/3;

   $image->string( font=>$font, text=>$text, x=>$x, y=>$y, size=>$size );
   print STDERR " " x ($debug_depth*3);
   print STDERR "text: @_\n";
   return;
}


#print Dumper($sample_data);
&render( $sample_data, 0, 0, 1023, 767 );
$image->write( file=>"test.png" );
#
# Input: a tree of array-hashes
# Output: none, sent to callbacks
#
sub render
{
   my ( @p, @q, $tree );
   ( $tree, $p[0], $p[1], $q[0], $q[1] ) = @_;

print STDERR "Initial values:\n\t$tree->{name}: @p, @q\n";
   # Draw our rectangle
   &{$rect}( $p[0], $p[1], $q[0], $q[1], $tree->{colour} );

   # Non-empty Set, Descend
   if( $tree->{children} )
   {
      # Check number of children 
      # If < 3, two slices on the longest side is optimal aspect ratio
      if( scalar(@{$tree->{children}}) < 3 )
      {
         my ( @r, @s, $o, $width );
         $o = ( abs($p[0]-$q[0]) > abs($p[1]-$q[1]) ? 0 : 1 );
         @r = @p;
         @s = @q;
         $width = abs( $s[$o] - $r[$o] );
         foreach my $child( @{$tree->{children}} )
         {
            $s[$o] = $r[$o] + $width * 
               ( $child->{size} / $tree->{size} ) if( $tree->{size} > 0 ); 
            &render( $child, $r[0], $r[1], $s[0], $s[1] );
            $r[$o] = $s[$o];
         }
      }
      # Otherwise, find optimal aspect ratio
      else
      {
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
         my ( $area, $parent_area, $parent_aspect, $usable_width, @j, @k, $o );
         $area = 0;
         $parent_area = $tree->{size};
         $usable_width = 0;
         @j = @p;
         @k = @q;
         $o = ( abs($j[0]-$k[0]) > abs($j[1]-$k[1]) ? 0 : 1 );

         while( @sorted_children > 0 )
         {
            # Adjust available area
            $parent_area -= $area;
            # Reset consumed area
            $area = 0;
            # Determine new boundary
            $j[$o] = $j[$o] + $usable_width;
            # Determine new orientation based on new boundary
            $o = ( abs($j[0]-$k[0]) > abs($j[1]-$k[1]) ? 0 : 1 );
            # Determine new parent aspect based on new boundary
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
               my $area_test = $area + $tree->{children}->[$child]->{size};
               my $aspect_test = $area_test / $scaled_height**2;
               $aspect_test = 1/$aspect_test if ( $aspect_test > 1 );
print STDERR "\t\tAspect: $aspect_test, $aspect\n";
               # If this aspect ratio is better than the last, keep searching
               if( ($aspect_test - $aspect) > 0 )
               {
                  # getting warmer, keep searching
                  $area = $area_test;
                  $aspect = $aspect_test;
                  push( @special_children, $child );
               }
               else
               {
                  # nope, last set was better, split the data, and send off two
                  # separate recursions
                  unshift( @sorted_children, $child );
                  last;
               }
            }
            # Handle special children
            if( @special_children > 0 )
            {
print STDERR "\t\t\tHandling Special Children: @special_children\n";
               my ( @r, @s );
               @r = @j;
               @s = @k;
               $usable_width = abs($j[$o]-$k[$o]) * ( $area / $parent_area );
print STDERR "\t\t\tUsable Width: $usable_width\n";
               my $o = ( abs($r[0]-$s[0]) > abs($r[1]-$s[1]) ? 0 : 1 );
               foreach my $child( @special_children )
               {
                  $s[$o] = $r[$o] + $usable_width * 
                     ( $tree->{children}->[$child]->{size} / $area ) 
                        if ( $area > 0 ); 
                  &render( $tree->{children}->[$child], 
                           $r[0], $r[1], $s[0], $s[1] 
                         );
                  $r[$o] = $s[$o];
               }
            }
            else
            {
print STDERR "No special children... awww\n";
            }
            # Continue processing remaining children at top of loop
         }
      }



   }
   # Draw label
   &{$text}( $p[0], $p[1], $q[0], $q[1], $tree->{name} );
}
1;
__END__

=head1 NAME 

Squarified Explained

=head1 SYNOPSIS

Make a Treemap, SQUARIFIED!!!

=head1 DESCRIPTION

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

If instead we take the inverse of the 'Aspect Ratio' when it is less than one,
we would get:

 Aspect
   |
   | \      /
   |  \    /
   |   \  /
   |    \/
   +---------- Y
 1        

This makes it easier to compare two aspect ratios when they span the perfect
aspect ratio of 1.

=head1 AUTHORS

Simon P. Ditner <simon@unitycode.org>, Eric Maki <fish@unitycode.org>

Original Treemap Concept: Ben Shneiderman <ben@cs.umd.edu>, http://www.cs.umd.edu/hcil/treemap-history/index.shtml

Squarified Treemap Concept: Visualization Group of the Technische Universiteit Eindhoven

=head1 BUGS

None yet :P

=head1 SEE ALSO

Treemap

=head1 COPYRIGHT

(c)2003

=end


