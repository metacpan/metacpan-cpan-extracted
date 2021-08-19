#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2016 -- leonerd@leonerd.org.uk

package Tickit::RectSet 0.72;

use v5.14;
use warnings;

use List::Util qw( min max );

# Load the XS code
require Tickit;

=head1 NAME

C<Tickit::RectSet> - store a set of rectangular regions

=head1 DESCRIPTION

Objects in this class store a set of rectangular regions. The object tracks
which areas are covered, to ensure that overlaps are avoided, and that
neighbouring regions are merged where possible. The order in which they are
added is not important.

New regions can be added using the C<add> method. The C<rects> method returns
a list of non-overlapping L<Tickit::Rect> regions, in top-to-bottom,
left-to-right order.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $rectset = Tickit::RectSet->new

Returns a new C<Tickit::RectSet> instance, initially empty.

=cut

=head1 METHODS

=cut

=head2 rects

   @rects = $rectset->rects

Returns a list of the covered regions, in order first top to bottom, then left
to right.

=cut

=head2 add

   $rectset->add( $rect )

Adds the region covered by C<$rect> to the stored region list.

=cut

=head2 subtract

   $rectset->subtract( $rect )

Removes any covered region that intersects with C<$rect> from the stored
region list.

=cut

=head2 clear

   $rectset->clear

Remove all the regions from the set.

=cut

=head2 intersects

   $bool = $rectset->intersects( $rect )

Returns true if C<$rect> intersects with any region in the set.

=cut

=head2 contains

   $bool = $rectset->contains( $rect )

Returns true if C<$rect> is entirely covered by the regions in the set. Note
that it may be that the rect requires two or more regions in the set to
completely cover it.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
