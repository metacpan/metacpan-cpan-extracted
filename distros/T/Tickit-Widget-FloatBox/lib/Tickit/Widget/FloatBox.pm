#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2020 -- leonerd@leonerd.org.uk

use 5.026; # signatures
use Object::Pad 0.17;

class Tickit::Widget::FloatBox 0.05
   extends Tickit::ContainerWidget;

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

=head2 new

   $floatbox = Tickit::Widget::FloatBox->new( %args )

Constructs a new C<Tickit::Widget::FloatBox> object.

Takes the following named arguments in addition to those taken by the base
L<Tickit::ContainerWidget> constructor.

=over 8

=item base_child => Tickit::Widget

The main L<Tickit::Widget> instance to use as the base.

This argument is now discouraged as it complicates the construction of
subclasses; see instead the L</set_base_child> method used as a chaining
mutator.

=back

=cut

has $_base_child;
has @_floats;

method BUILD ( %args )
{
   if( $args{base_child} ) {
      Carp::carp( "The 'base_child' constructor argument to ${\ref $self} is discouraged; use ->set_base_child instead" );
      $self->set_base_child( $args{base_child} );
   }
}

=head1 ACCESSORS

=cut

method children ()
{
   my @children;

   push @children, $self->base_child if $self->base_child;
   push @children, $_->child for @_floats;

   return @children;
}

method lines ()
{
   return $self->base_child ? $self->base_child->requested_lines : 1;
}

method cols ()
{
   return $self->base_child ? $self->base_child->requested_cols : 1;
}

=head2 base_child

=head2 set_base_child

   $base_child = $floatbox->base_child

   $floatbox->set_base_child( $base_child )

Returns or sets the base widget to use.

The mutator method returns the container widget instance itself making it
suitable to use as a chaining mutator; e.g.

   my $container = Tickit::Widget::FloatBox->new( ... )
      ->set_base_child( Tickit::Widget::Box->new ... );

=cut

method base_child () { $_base_child }

method set_base_child ( $new )
{
   if( $_base_child ) {
      $self->remove( $_base_child );
   }

   $_base_child = $new;
   $self->add( $new );

   if( my $win = $self->window ) {
      $new->set_window( $win->make_sub( 0, 0, $win->lines, $win->cols ) );
   }

   return $self;
}

method reshape ()
{
   return unless my $win = $self->window;

   if( $_base_child ) {
      if( $_base_child->window ) {
         $_base_child->window->resize( $win->lines, $win->cols );
      }
      else {
         $_base_child->set_window( $win->make_sub( 0, 0, $win->lines, $win->cols ) );
      }
   }

   $self->_reshape_float( $_, $win ) for @_floats;

   $self->redraw;
}

method _reshape_float ( $float, $win )
{
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
      $child->window->hide if !$float->is_visible;
   }
}

method render_to_rb ( $rb, $rect )
{
   return if $self->base_child;

   $rb->eraserect( $rect );
}

=head2 add_float

   $float = $floatbox->add_float( %args )

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

method add_float ( %args )
{
   my $float = Tickit::Widget::FloatBox::Float->new(
      $self, delete $args{child}, %args
   );
   push @_floats, $float;

   $self->add( $float->child );

   if( my $win = $self->window ) {
      $self->_reshape_float( $float, $win );
   }

   return $float;
}

method _remove_float ( $float )
{
   my $idx;
   $_floats[$_] == $float and $idx = $_, last for 0 .. $#_floats;
   defined $idx or croak "Cannot remove float - not a member of the FloatBox";

   splice @_floats, $idx, 1, ();

   $self->remove( $float->child );
}

=head1 FLOATS

The following objects represent a floating region as returned by the
C<add_float> method.

=cut

class # hide
   Tickit::Widget::FloatBox::Float;

use Carp;

has $_fb;
has $_child;
has $_hidden;
has %_geom;

method BUILD ()
{
   ( $_fb, $_child, my %args ) = @_;
   $_hidden = delete $args{hidden} || 0;

   $self->move( %args );
}

=head2 child

   $child = $float->child

Returns the child widget in the region.

=cut

method child () { $_child }

=head2 move

   $float->move( %args )

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

method move ( %args )
{
   exists $args{$_} and $_geom{$_} = $args{$_} for qw( top bottom left right );

   defined $_geom{top} or defined $_geom{bottom} or
      croak "A Float needs at least one of 'top' or 'bottom'";
   defined $_geom{left} or defined $_geom{right} or
      croak "A Float needs at least one of 'left' or 'right'";

   if( my $win = $_fb->window ) {
      $_fb->_reshape_float( $self, $win );
   }
}

method _get_geom ( $lines, $cols )
{
   my $clines = $self->child->requested_lines;
   my $ccols  = $self->child->requested_cols;

   my ( $top, $bottom ) = _alloc_dimension( $_geom{top}, $_geom{bottom}, $lines, $clines );
   my ( $left, $right ) = _alloc_dimension( $_geom{left}, $_geom{right}, $cols,  $ccols  );

   return ( $top, $left, $bottom-$top, $right-$left );
}

sub _alloc_dimension ( $start, $end, $parentsz, $childsz )
{
   # Need to off-by-one to allow -1 == right, etc..
   defined and $_ < 0 and $_ += $parentsz+1 for $start, $end;

   $end   = $start + $childsz if !defined $end;
   $start = $end   - $childsz if !defined $start;

   return ( $start, $end );
}

=head2 remove

   $float->remove

Removes the float from the FloatBox.

=cut

method remove ()
{
   $_fb->_remove_float( $self );
}

=head2 hide

   $float->hide

Hide the float by hiding the window of its child widget.

=cut

method hide ()
{
   my $self = shift;
   $_hidden = 1;

   $_child->window->hide if $_child->window;
}

=head2 show

   $float->show

Show the float by showing the window of its child widget. Undoes the effect
of C<hide>.

=cut

method show ()
{
   $_hidden = 0;

   $_child->window->show if $_child->window;
}

=head2 is_visible

   $visible = $float->is_visible

Return true if the float is currently visible.

=cut

method is_visible ()
{
   return !$_hidden;
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
