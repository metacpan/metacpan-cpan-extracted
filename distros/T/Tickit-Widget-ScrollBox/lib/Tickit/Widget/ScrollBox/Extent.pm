#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2020 -- leonerd@leonerd.org.uk

use 5.026; # signatures
use Object::Pad 0.27;

package Tickit::Widget::ScrollBox::Extent 0.09;
class Tickit::Widget::ScrollBox::Extent;

use Scalar::Util qw( weaken );

=head1 NAME

C<Tickit::Widget::ScrollBox::Extent> - represents the range of scrolling extent

=head1 DESCRIPTION

This small utility object stores the effective scrolling range for a
L<Tickit::Widget::ScrollBox>. They are not constructed directly, but instead
returned by the C<hextent> and C<vextent> methods of the associated ScrollBox.

=cut

has $_start = 0;
has $_total;

has $_scrollbox;
has $_id;

BUILD ( $scrollbox, $id )
{
   weaken( $_scrollbox = $scrollbox );
   $_id = $id;
}

method _clamp ()
{
   my $limit = $self->total - $self->viewport;
   $_start = $limit if $_start > $limit;
}

# Internal; used by T:W:ScrollBox
has $_viewport;

method set_viewport ( $viewport )
{
   $_viewport = $viewport;
   $self->_clamp if defined $_total;
}

=head1 ACCESSORS

=cut

=head2 viewport

   $viewport = $extent->viewport

Returns the size of the viewable portion of the scrollable area (the
"viewport").

=cut

method viewport { $_viewport }

=head2 total

   $total = $extent->total

Returns the total size of the scrollable area; which is always at least the
size of the viewport.

=head2 set_total

   $extent->set_total( $total )

Sets the total size of the scrollable area. This method should only be used by
the child widget, when it is performing smart scrolling.

=cut

method total ()
{
   my $viewport = $_viewport;
   my $total    = $_total;
   $total = $viewport if $viewport > $total;
   return $total;
}

method real_total () { $_total }

method set_total ( $total )
{
   return if defined $_total and $_total == $total;

   $_total = $total;
   $self->_clamp if defined $_viewport;

   $_scrollbox->_extent_scrolled( $_id, 0, undef );
}

=head2 limit

   $limit = $extent->limit

Returns the limit of the offset; the largest value the start offset may be.
This is simply C<$total - $viewport>, with a limit applied so that it returns
zero rather than a negative value, in the case that the viewport is larger
than the total.

=cut

method limit ()
{
   my $limit = $_total - $_viewport;
   $limit = 0 if $limit < 0;
   return $limit;
}

=head2 start

   $start = $extent->start

Returns the start position offset of the viewport within the total area. This
is always at least zero, and no greater than the limit.

=cut

method start () { $_start }

=head1 METHODS

=cut

=head2 scroll

   $extent->scroll( $delta )

Requests to move the start by the amount given. This will be clipped if it
moves outside the allowed range.

=cut

method scroll ( $delta )
{
   $self->scroll_to( $self->start + $delta );
}

=head2 scroll_to

   $extent->scroll_to( $new_start )

Requests to move the start to that given. This will be clipped if it is
outside the allowed range.

=cut

method scroll_to ( $start )
{
   my $limit = $self->limit;
   $start = $limit if $start > $limit;

   $start = 0 if $start < 0;

   return if $_start == $start;

   my $delta = $start - $_start;

   $_start = $start;
   $_scrollbox->_extent_scrolled( $_id, $delta, $start );
}

=head2 scrollbar_geom

   ( $bar_top, $mark_top, $mark_bottom, $bar_bottom ) = $extent->scrollbar_geom( $top, $length )

Calculates the start and end positions of a scrollbar and the mark within it
to represent the position of the extent. Returns four integer indexes within
C<$length>.

=cut

method scrollbar_geom ( $top, $length )
{
   my $total = $self->total;

   my $bar_length = int( $self->viewport * $length / $total + 0.5 );
   $bar_length = 1 if $bar_length < 1;

   my $bar_start = $top + int( $self->start * $length / $total + 0.5 );

   return ( $top, $bar_start, $bar_start + $bar_length, $top + $length );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
