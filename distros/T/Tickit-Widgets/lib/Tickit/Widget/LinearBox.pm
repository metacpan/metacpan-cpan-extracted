#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2023 -- leonerd@leonerd.org.uk

use v5.20;
use warnings;
use Object::Pad 0.807;

package Tickit::Widget::LinearBox 0.55;
class Tickit::Widget::LinearBox :strict(params);

inherit Tickit::ContainerWidget;

use experimental 'postderef';

use Tickit::RenderBuffer;

use Carp;
use Syntax::Keyword::Dynamically;

use Tickit::Utils qw( distribute );

use List::Util qw( sum );

=head1 NAME

C<Tickit::Widget::LinearBox> - abstract base class for C<HBox> and C<VBox>

=head1 DESCRIPTION

This class is a base class for both L<Tickit::Widget::HBox> and
L<Tickit::Widget::VBox>. It is not intended to be used directly.

It maintains an ordered list of child widgets, and implements the following
child widget options:

=over 8

=item expand => NUM

A number used to control how extra space is distributed among child widgets,
if the window containing this widget has more space available to it than the
children need. The actual value is unimportant, but extra space will be
distributed among the children in proportion with their C<expand> value.

For example, if all the children have a C<expand> value of 1, extra space is
distributed evenly. If one child has a value of 2, it will gain twice as much
extra space as its siblings. Any child with a value of 0 will obtain no extra
space.

=item force_size => NUM

If provided, forces the size of this child widget, overriding the value
returned by C<get_child_base>.

=back

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $widget = Tickit::Widget::LinearBox->new( %args );

Returns a new C<Tickit::Widget::LinearBox>.

=cut

field @_children;

field $_suppress_redistribute;

sub BUILDARGS
{
   my $class = shift;
   my %args = @_;

   exists $args{$_} and $args{style}{$_} = delete $args{$_} for qw( spacing );

   return $class->SUPER::BUILDARGS( %args );
}

=head1 METHODS

=cut

=head2 children

   @children = $widget->children;

In scalar context, returns the number of contained children. In list context,
returns a list of all the child widgets.

=cut

method children
{
   return @_children;
}

method _any2index
{
   my ( $target ) = @_;
   if( ref $target ) {
      my $child = $target;
      $_children[$_] == $child and return $_ for 0 .. $#_children;
      croak "Unable to find child $child";
   }
   else {
      my $index = $target;
      return $index if $index >= 0 and $index < scalar @_children;
      croak "Index $index out of bounds";
   }
}

=head2 child_opts

   %opts = $widget->child_opts( $child_or_index );

Returns the options currently set for the given child, specified either by
reference or by index.

=cut

method child_opts
{
   my ( $target ) = @_;
   my $child = ref $target ? $target : $_children[$target];

   return unless $child;

   return $self->SUPER::child_opts( $child );
}

=head2 set_child

   $widget->set_child( $index, $child );

Replaces the child widget at the given index with the given new one;
preserving any options that are set on it.

=cut

method set_child
{
   my ( $index, $child ) = @_;

   my $old_child = $_children[$index];

   my %opts;
   if( $old_child ) {
      %opts = $self->child_opts( $old_child );

      dynamically $_suppress_redistribute = 1;
      $self->SUPER::remove( $old_child );
   }

   $_children[$index] = $child;

   $self->SUPER::add( $child, %opts );
}

=head2 set_child_opts

   $widget->set_child_opts( $child_or_index, %newopts );

Sets new options on the given child, specified either by reference or by
index. Any options whose value is given as C<undef> are deleted.

=cut

method set_child_opts
{
   my ( $target, @opts ) = @_;
   my $child = ref $target ? $target : $_children[$target];

   return unless $child;

   return $self->SUPER::set_child_opts( $child, @opts );
}

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );

   if( $self->get_style_values( "spacing" ) > 0 and @_children and
         my $line_style = $self->get_style_values( "line_style" ) ) {
      my $line_pen = $self->get_style_pen( "line" );
      my $prev_win = $_children[0]->window;

      foreach my $idx ( 1 .. $#_children ) {
         my $next_win = $_children[$idx]->window
            or next;

         $self->render_dividing_line( $rb, $prev_win, $next_win,
            $line_style, $line_pen ) if $prev_win;

         $prev_win = $next_win;
      }
   }
}

=head2 add

   $widget->add( $child, %opts );

Adds the widget as a new child of this one, with the given options.

This method returns the container widget instance itself making it suitable to
use as a chaining mutator; e.g.

   my $container = Tickit::Widget::LinearBox->new( ... )
      ->add( Tickit::Widget::Static->new( ... ) )
      ->add( Tickit::Widget::Static->new( ... ) );

=cut

method add
{
   my ( $child, %opts ) = @_;

   push @_children, $child;

   $self->SUPER::add( $child,
      expand     => $opts{expand} || 0,
      force_size => $opts{force_size},
   );

   return $self;
}

=head2 add_children

   $widget->add_children( @children );

Adds each of the given widgets as a new child of this one. Each element of the
list should either be a widget object reference directly, or an unblessed hash
reference containing additional options. (See
L<Tickit::Widget/split_widget_opts>).

This method returns the container widget instance itself making it suitable to
use as a chaining mutator.

=cut

sub add_children
{
   my $self = shift;

   foreach my $arg ( @_ ) {
      $self->add( Tickit::Widget::split_widget_opts $arg );
   }

   return $self;
}

=head2 remove

   $widget->remove( $child_or_index );

Removes the given child widget if present, by reference or index

=cut

method remove
{
   my $index = $self->_any2index( shift );

   my ( $child ) = splice @_children, $index, 1, ();

   $self->SUPER::remove( $child ) if $child;
}

method reshape
{
   $_suppress_redistribute and return;

   my $window = $self->window;

   return unless $self->children;

   my $spacing = $self->get_style_values( "spacing" );

   my @buckets;
   foreach my $child ( $self->children ) {
      my %opts = $self->child_opts( $child );

      push @buckets, {
         fixed => $spacing,
      } if @buckets; # gap

      my $base = defined $opts{force_size} ? $opts{force_size}
                                           : $self->get_child_base( $child );
      warn "Child $child did not define a base size for $self\n", $base = 0
         unless defined $base;

      push @buckets, {
         base   => $base,
         expand => $opts{expand},
         child  => $child,
      };
   }

   distribute( $self->get_total_quota( $window ), @buckets );

   foreach my $b ( @buckets ) {
      my $child = $b->{child} or next;

      $self->set_child_window( $child, $b->{start}, $b->{value}, $window );
   }

   $self->redraw;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
