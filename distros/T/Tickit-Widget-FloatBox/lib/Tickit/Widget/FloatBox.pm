#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Tickit::Widget::FloatBox;

use strict;
use warnings;
use base qw( Tickit::ContainerWidget );

our $VERSION = '0.03';

use Carp;

# We don't actually have a pen, but then we don't actually have any style
# either. This keeps deprecation warnings happy
use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 NAME

C<Tickit::Widget::FloatBox> - manage a collection of floating widgets

=head1 SYNOPSIS

 TODO

=head1 DESCRIPTION

This container widget maintains a collection of floating widgets that can be
displayed over the top of a single base widget. The box itself is entirely
occupied by the base widget, and by default when no floats are created or
displayed it will behave essentially invisibly, as though the box were not
there and the base widget was an immediate child of the container the floatbox
is inside.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $floatbox = Tickit::Widget::FloatBox->new( %args )

Constructs a new C<Tickit::Widget::FloatBox> object.

Takes the following named arguments in addition to those taken by the base
L<Tickit::ContainerWidget> constructor.

=over 8

=item base_child => Tickit::Widget

The main L<Tickit::Widget> instance to use as the base.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->set_base_child( $args{base_child} ) if $args{base_child};
   $self->{floats} = [];

   return $self;
}

=head1 ACCESSORS

=cut

sub children
{
   my $self = shift;
   my @children;

   push @children, $self->base_child if $self->base_child;
   push @children, $_->child for @{ $self->{floats} };

   return @children;
}

sub lines
{
   my $self = shift;
   return $self->base_child ? $self->base_child->requested_lines : 1;
}

sub cols
{
   my $self = shift;
   return $self->base_child ? $self->base_child->requested_cols : 1;
}

=head2 $base_child = $floatbox->base_child

=head2 $floatbox->set_base_child( $base_child )

Returns or sets the base widget to use.

=cut

sub base_child
{
   my $self = shift;
   return $self->{base_child};
}

sub set_base_child
{
   my $self = shift;
   my ( $new ) = @_;

   if( my $old = $self->{base_child} ) {
      $self->remove( $old );
   }

   $self->{base_child} = $new;
   $self->add( $new );

   if( my $win = $self->window ) {
      $new->set_window( $win->make_sub( 0, 0, $win->lines, $win->cols ) );
   }
}

sub reshape
{
   my $self = shift;

   return unless my $win = $self->window;

   if( my $child = $self->base_child ) {
      if( $child->window ) {
         $child->window->resize( $win->lines, $win->cols );
      }
      else {
         $child->set_window( $win->make_sub( 0, 0, $win->lines, $win->cols ) );
      }
   }

   $self->_reshape_float( $_, $win ) for @{ $self->{floats} };

   $self->redraw;
}

sub _reshape_float
{
   my $self = shift;
   my ( $float, $win ) = @_;

   my $child = $float->child;
   my @geom = $float->_get_geom( $win->lines, $win->cols );

   if( my $childwin = $child->window ) {
      $childwin->expose;
      $childwin->change_geometry( @geom );
      $childwin->expose;
   }
   else {
      # TODO: Ordering?
      # TODO: I want a ->make_hidden_float
      $child->set_window( $win->make_float( @geom ) );
      $child->window->hide if $float->{hidden};
   }
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   return if $self->base_child;

   $rb->eraserect( $rect );
}

=head2 $float = $floatbox->add_float( %args )

Adds a widget as a floating child and returns a new C<Float> object. Takes the
following arguments:

=over 8

=item child => Tickit::Widget

The child widget

=item top, bottom, left, right => INT

The initial geometry of the floating area. These follow the same behaviour as
the C<move> method on the Float object.

=item hidden => BOOL

Optional. If true, the float starts off hidden initally, and must be shown by
the C<show> method before it becomes visible.

=back

=cut

sub add_float
{
   my $self = shift;
   my %args = @_;

   my $float = Tickit::Widget::FloatBox::Float->new(
      $self, delete $args{child}, %args
   );
   push @{ $self->{floats} }, $float;

   $self->add( $float->child );

   if( my $win = $self->window ) {
      $self->_reshape_float( $float, $win );
   }

   return $float;
}

sub _remove_float
{
   my $self = shift;
   my ( $float ) = @_;

   my $idx;
   $self->{floats}[$_] == $float and $idx = $_, last for 0 .. $#{ $self->{floats} };
   defined $idx or croak "Cannot remove float - not a member of the FloatBox";

   splice @{ $self->{floats} }, $idx, 1, ();

   $self->remove( $float->child );
}

=head1 FLOATS

The following objects represent a floating region as returned by the
C<add_float> method.

=cut

package # hide
   Tickit::Widget::FloatBox::Float;

use Carp;

sub new
{
   my $class = shift;
   my ( $fb, $child, %args ) = @_;

   my $self = bless {
      fb     => $fb,
      child  => $child,
      hidden => delete $args{hidden} || 0,
   }, $class;

   $self->move( %args );

   return $self;
}

=head2 $child = $float->child

Returns the child widget in the region.

=cut

sub child { shift->{child} }

=head2 $float->move( %args )

Redefines the area geometry of the region. Takes arguments named C<top>,
C<bottom>, C<left> and C<right>, each of which should either be a numeric
value, or C<undef>.

The region must have at least one of C<top> or C<bottom> and at least one of
C<left> or C<right> defined, which will then fix the position of one corner of
the region. If the size is not otherwise determined by the geometry, it will
use the preferred size of the child widget. Any geometry argument may be
negative to count backwards from the limits of the parent.

For example,

 # top-left corner
 $float->move( top => 0, left => 0 )

 # top-right corner
 $float->move( top => 0, right => -1 )

 # bottom 3 lines, flush left
 $float->move( left => 0, top => -3, bottom => -1 )

Any arguments not passed will be left unchanged; to specifically clear the
current value pass a value of C<undef>.

=cut

sub move
{
   my $self = shift;
   my %args = @_;

   exists $args{$_} and $self->{$_} = $args{$_} for qw( top bottom left right );

   defined $self->{top} or defined $self->{bottom} or
      croak "A Float needs at least one of 'top' or 'bottom'";
   defined $self->{left} or defined $self->{right} or
      croak "A Float needs at least one of 'left' or 'right'";

   if( my $win = $self->{fb}->window ) {
      $self->{fb}->_reshape_float( $self, $win );
   }
}

sub _get_geom
{
   my $self = shift;
   my ( $lines, $cols ) = @_;

   my $clines = $self->child->requested_lines;
   my $ccols  = $self->child->requested_cols;

   my ( $top, $bottom ) = _alloc_dimension( $self->{top}, $self->{bottom}, $lines, $clines );
   my ( $left, $right ) = _alloc_dimension( $self->{left}, $self->{right}, $cols,  $ccols  );

   return ( $top, $left, $bottom-$top, $right-$left );
}

sub _alloc_dimension
{
   my ( $start, $end, $parentsz, $childsz ) = @_;

   # Need to off-by-one to allow -1 == right, etc..
   defined and $_ < 0 and $_ += $parentsz+1 for $start, $end;

   $end   = $start + $childsz if !defined $end;
   $start = $end   - $childsz if !defined $start;

   return ( $start, $end );
}

=head2 $float->remove

Removes the float from the FloatBox.

=cut

sub remove
{
   my $self = shift;
   $self->{fb}->_remove_float( $self );
}

=head2 $float->hide

Hide the float by hiding the window of its child widget.

=cut

sub hide
{
   my $self = shift;
   $self->{hidden} = 1;

   $self->child->window->hide if $self->child->window;
}

=head2 $float->show

Show the float by showing the window of its child widget. Undoes the effect
of C<hide>.

=cut

sub show
{
   my $self = shift;
   $self->{hidden} = 0;

   $self->child->window->show if $self->child->window;
}

=head2 $visible = $float->is_visible

Return true if the float is currently visible.

=cut

sub is_visible
{
   my $self = shift;
   return !$self->{hidden};
}

=head1 TODO

=over 4

=item *

Support adjusting stacking order of floats.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA
