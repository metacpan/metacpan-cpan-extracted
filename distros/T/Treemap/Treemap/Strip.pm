package Treemap::Strip;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter Treemap);
our @EXPORT_OK = (  );
our @EXPORT = qw( );
our $VERSION = '0.01';


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
   my $self = {};

   # set default "draw" functions
   $self->{ RECT } = \&rect;
   $self->{ TEXT } = \&text;

   bless $self, $class;
   return $self;
}

sub map
{
   my $self = shift;
   my ( @p, @q, $tree, $o );
   ( $tree, $p[0], $p[1], $q[0], $q[1], $o ) = @_;
   $o = $o || 0;  # Orientation of our slicing

   # Draw our rectangle
   &{$self->{ RECT }}( $p[0], $p[1], $q[0], $q[1], $tree->{colour} );

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
         $self->map( $child, $r[0], $r[1], $s[0], $s[1], ($o xor 1) );
         $r[$o] = $s[$o];
      }
   }
   # Draw label
   # &{ $self->{ TEXT } }( $tree->{name} );
}


1;

__END__

# ------------------------------------------
# Documentation:
# ------------------------------------------

=head1 NAME

Treemap - Create Treemaps from arbitrary data. 

=head1 SYNOPSIS

  use Treemap;
  $tmap = Treemap->new();

=head1 DESCRIPTION

Create Treemaps from arbitrary data.  

=head2 EXPORT

None by default.

=head1 AUTHOR

 Simon Ditner, <simon@uc.org>
 Eric Maki, <eric@uc.org>

=head1 SEE ALSO

L<perl>.

=cut
