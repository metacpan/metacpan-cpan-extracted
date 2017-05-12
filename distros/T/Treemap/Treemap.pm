package Treemap;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = (  );
our @EXPORT = qw( );
our $VERSION = '0.02';


# ------------------------------------------
# Methods:
# ------------------------------------------


# ------------------------------------------
# new() - Create and return new Treemap 
#         object:
# ------------------------------------------
sub new 
{
   my $proto = shift;
   my $class = ref( $proto ) || $proto;
   my $self = {
      RECT => undef,
      TEXT => undef,
      CACHE => 1,
      INPUT => undef,
      OUTPUT => undef,
      PADDING => 5,
      SPACING => 5,
      @_,               # Override previous attributes
   };

   die "No 'INPUT' object was specified in call to " . $class . "::new, cannot proceed.\nSee: perldoc Treemap\nError occured" if ( ! $self->{INPUT} );
   die "No 'OUTPUT' object was specified in call to " . $class . "::new, cannot proceed.\nSee: perldoc Treemap\nError occured" if ( ! $self->{OUTPUT} );

   # set default "draw" functions
#   $self->{ RECT } = \&rect;
#   $self->{ TEXT } = \&text;

   bless $self, $class;
   return $self;
}

sub rect
{
   print " ";
   print "rect: @_\n";
}

sub text
{
   print " ";
   print "text: @_\n";
}

sub map
{
   my $self = shift;

   # Get dimensions from OUTPUT object
   my $width = $self->{OUTPUT}->width;
   my $height=  $self->{OUTPUT}->height;

   # Call _map function with tree data from INPUT object.
   $self->_map( $self->{INPUT}->treedata, 0, 0, $width-1, $height-1 );
}

sub _map
{
   my $self = shift;
   my ( @p, @q, $tree, $o );
   ( $tree, $p[0], $p[1], $q[0], $q[1], $o ) = @_;
   $o = $o || 0;  # Orientation of our slicing

   # Draw our rectangle
   #&{$self->{ RECT }}( $p[0], $p[1], $q[0], $q[1], $tree->{colour} );
   $self->{ OUTPUT }->rect( $p[0], $p[1], $q[0], $q[1], $tree->{colour} );

   # Shrink the space available to children
   my( $pt, $qt ) = $self->_shrink( \@p, \@q, $self->{PADDING} );
   my @r = @$pt; my @s = @$qt;

   # Non-empty Set, Descend
   if( $tree->{children} )
   {
      my $width = abs($r[$o] - $s[$o]);
      my $size = $tree->{size};

      # Process each child
      foreach my $child( @{$tree->{children}} )
      {
         # Give this child a percentage of the parent's space, based on
         # parent's size (make sure we don't cause divide by zero errors)
         $s[$o] = $r[$o] + $width * ( $child->{size} / $size ) if ( $size > 0 );

         # Rotate the space by 90 degrees, by xor'ing the 'o'rientation
         {
            my( $rt, $st ) = $self->_shrink( \@r, \@s, $self->{SPACING} );
            my @r = @{$rt}; my @s = @{$st};
            $self->_map( $child, $r[0], $r[1], $s[0], $s[1], ($o xor 1) );
         }
         $r[$o] = $s[$o];
      }
   }
   # Draw label
   #&{ $self->{ TEXT } }( $tree->{name} );
   $self->{ OUTPUT }->text( $p[0], $p[1], $q[0], $q[1], $tree->{name}, ($tree->{children}?1:undef) );
}

sub _shrink
{
   my $self = shift;
   my ( $p, $q, $shr ) = @_;
   my ( $w, $h, $r, $s );
   my ( $w_shrink, $h_shrink ) = ( 0, 0 );

   $w = $q->[0] - $p->[0];
   $h = $q->[1] - $p->[1];

# Shrinking by %
#
# +----------W1-----------+
# |                       |
# |  +-------W2--------+  |
# |  |                 |  |
# H1 H2                |  |
# |  |              A2 |  |
# |  +-----------------+  |
# |                    A1 |
# +-----------------------+
#
# A2 = A1*PCT
# H2*W2 = H1*W1*PCT  (1)
# 
# Since aspect ratio is constant:
#
# H2/W2 = H1/W1
# H2 = (H1*W2)/W1
#
# From (1):
#
# H2*W2 = H1*W1*PCT
# W2*(H1*W2)/W1 = H1*W1*PCT
# W2^2*H1/W1 = H1*W1*PCT
# W2^2 = W1^2*PCT
# W2 = (W1^2*PCT)^0.5
#
   if ( $shr =~ /^([\d]+)%$/ )
   {
      my $pct = ( 100 - $1 ) / 100;
      my $w2 = (($w**2)*$pct)**0.5;
      $shr = ( abs($w) - $w2 ) / 2;
   }

# SLOPPY!!!
# These two if structures should be in a simple loop.....
# SLOPPY!!!
   if ( abs( $w ) >= $shr )
   {
      if ( $w > 0 )
      {
         $w_shrink = $shr;
      }
      elsif( $w < 0 )
      {
         $w_shrink = - $shr;
      }
   }
   # We can't shrink by that factor, so shrink as much as we can
   else
   {
      $w_shrink = $w / 2;
   }

   if ( abs( $h ) >= $shr )
   {
      if ( $h > 0 )
      {
         $h_shrink = $shr;
      }
      elsif( $h < 0 )
      {
         $h_shrink = - $shr;
      }
   }
   # We can't shrink by that factor, so shrink as much as we can
   else
   {
      $h_shrink = $h / 2;
   }

   # Perfomr shrink
   $self->{DEBUG} && print "Shrinking by $w_shrink, $h_shrink\n";
   $r->[0] = $p->[0] + $w_shrink;
   $r->[1] = $p->[1] + $h_shrink;

   $s->[0] = $q->[0] - $w_shrink;
   $s->[1] = $q->[1] - $h_shrink;
   return ( $r, $s );
}

1;

__END__

# ------------------------------------------
# Documentation:
# ------------------------------------------

=head1 NAME

Treemap - Create Treemaps from various sources of data.

=head1 SYNOPSIS

 #!/usr/bin/perl -w
 use Treemap::Squarified;
 use Treemap::Input::Dir;
 use Treemap::Output::Imager;
 
 my $dir = Treemap::Input::Dir->new();
 my $imager = Treemap::Output::Imager->new( WIDTH=>1024, HEIGHT=>768, 
                                            FONT_FILE=>"ImUgly.ttf" );
 $dir->load( "/home" );
 
 my $treemap = new Treemap::Squarified( INPUT=>$dir, OUTPUT=>$imager );
 $treemap->map();
 $imager->save( "test.png" );

=head1 DESCRIPTION

This base class is not meant to be directly instantiated. Subclasses of Treemap
which implement specific Treemap layout algorithms should be instantiated
instead. See the SEE ALSO section below for a list.

Traditional representations of hiarchal information trees are very space
consuming.  There is a large amount of redundant information and padding to
convey the tree structure.

Treemaps are representations of trees that use space-filling nested
rectangles to convey the tree structure. 

e.g., a directory tree:

   2       ./CVS/Root
   2       ./CVS/Repository
   2       ./CVS/Entries
   2       ./CVS/Entries.Log
   10      ./CVS
   2       ./Treemap/CVS/Root
   2       ./Treemap/CVS/Repository
   2       ./Treemap/CVS/Entries
   2       ./Treemap/CVS/Entries.Log
   .
   .
   .
   (goes on for 80 lines)

e.g., a treemap of a directory tree:

 .-------------------------------.
 |             ROOT              |
 |.-----------..-------..-------.|
 ||ImUgly.ttf ||Treemap||  CVS  ||
 ||           ||.-----.||       ||
 ||           |||Input|||       ||
 ||           |||     || >-----< |
 ||           || >---< ||example||
 ||           |||Outpu|||       ||
 ||           ||`_____'||       ||
 |`-----------'`-------'`-------'|
 `-------------------------------'

Raster output is much more useful (like a GIF, or PNG) than ascii, as the
labels are scaled appropriately, and alpha transparency is used to show
information that would otherwise be hidden.

=head1 METHODS

=over 4

=item new()

=over 4

=item INPUT

A Treemap::Input object reference.

=item OUTPUT

A Treemap::Output object reference.

=item PADDING 

Distance between in a parent rectangle, and all it's children in points.
Points being whatever unit of measurement the drawing routines of the output
object uses.

=item SPACING 

Spacing around the outside of a rectangle in points. Points being whatever unit
of measurement the drawing routines of the output object uses.

=back 4

For a wondeful surprise, set PADDING, and SPACING to zero. It's more difficult
to see the nesting, but it reveals other structures that you likely won't see
unless you render your treemap at an extremely high resolution.

=item map()

Perform the actual operation of treemapping.

=back 4

=head1 EXPORT

None by default.

=head1 SEE ALSO

Treemap Layout Classes:

L<Treemap::Strip>, L<Treemap::Squarified>

Treemap Input Classes:

L<Treemap::Input>

Treemap Output Classes:

L<Treemap::Output>

=head1 BUGS

Subclasses should autoload in some manner to ease developer use.

Violates data incapsulation, and reaches into the innards of Treemap::Input objects. It really shouldn't do that.

=head1 AUTHORS

Simon Ditner <simon@uc.org>, and Eric Maki <eric@uc.org>

=head1 CREDITS

Original Treemap Concept: Ben Shneiderman <ben@cs.umd.edu>,
http://www.cs.umd.edu/hcil/treemap-history/index.shtml

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
