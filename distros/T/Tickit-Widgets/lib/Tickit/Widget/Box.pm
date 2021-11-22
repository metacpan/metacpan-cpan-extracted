#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2021 -- leonerd@leonerd.org.uk

use Object::Pad 0.57;

package Tickit::Widget::Box 0.56;
class Tickit::Widget::Box
   :isa(Tickit::SingleChildWidget);

use Carp;

use Tickit::Style;
use Tickit::RenderBuffer;

use Tickit::Utils qw( bound );

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 NAME

C<Tickit::Widget::Box> - apply spacing and positioning to a widget

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::Box;
   use Tickit::Widget::Static;

   my $box = Tickit::Widget::Box->new(
      bg => "green",
      child_lines => "80%",
      child_cols  => "80%",
   )
      ->set_child(
         Tickit::Widget::Static->new(
           text   => "Hello, world!",
           bg     => "black",
           align  => "centre",
           valign => "middle",
         )
      );

   Tickit->new( root => $box )->run;

=head1 DESCRIPTION

This subclass of L<Tickit::SingleChildWidget> can apply spacing around the
outside of a given child widget. The size of the Box is controlled by the size
of the child widget bounded by the given limits, allowing it to enforce a
given minimum or maximum size in each of the horizontal and vertical
directions. By setting both the minimum and maximum size to the same value,
the exact size of the child widget can be controlled.

Limits can be specified either as absolute values, or as a percentage of the
maxmium available space.

If the Box is given more space to use than the child widget will consume, the
child will be placed somewhere within the space, at a position that is
controllable using the C<align> and C<valign> properties, as defined by
L<Tickit::WidgetRole::Alignable>.

=head1 STYLE

The default style pen is used as the widget pen.

Note that while the widget pen is mutable and changes to it will result in
immediate redrawing, any changes made will be lost if the widget style is
changed.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $box = Tickit::Widget::Box->new( %args )

In addition to the constructor arguments allowed by C<Tickit::Widget> and
C<Tickit::SingleChildWidget>, this constructor also recognises the following
named arguments:

=over 8

=item child_{lines,cols}_{min,max} => NUM or STRING

Initial values for size limit options.

=item child_{lines,cols} => NUM or STRING

Initial values for size forcing options.

=item align => NUM or STRING

=item valign => NUM or STRING

Initial values for alignment options.

=back

=cut

ADJUSTPARAMS
{
   my ( $params ) = @_;

   foreach (qw( child_lines_min child_lines_max child_cols_min child_cols_max
                child_lines                     child_cols )) {
      my $val = delete $params->{$_};
      $self->${\"set_$_"}( $val ) if defined $val;
   }

   foreach (qw( align valign )) {
      my $val = delete $params->{$_};
      $self->${\"set_$_"}( $val // 0.5 );
   }

   if( exists $params->{child} ) {
      croak "The 'child' constructor argument to ${\ref $self} is no longer recognised; use ->add_child instead";
   }
}

method lines
{
   my $child = $self->child;
   return $child ? bound( $self->child_lines_min, $child->requested_lines, $self->child_lines_max ) : 1;
}

method cols
{
   my $child = $self->child;
   return $child ? bound( $self->child_cols_min, $child->requested_cols, $self->child_cols_max ) : 1;
}

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );
}

=head1 METHODS

The following methods all accept either absolute sizes, specified in integers,
or percentages, specified in strings of the form C<10%>. If a percentage is
given it specifies a size that is a fraction of the total amount that is
available to the Box.

=head2 child_lines_min

=head2 set_child_lines_min

=head2 child_cols_min

=head2 set_child_cols_min

   $min = $box->child_lines_min

   $box->set_child_lines_min( $min )

   $min = $box->child_cols_min

   $box->set_child_cols_min( $min )

Accessors for the child size minimum limits. If the child widget requests a
size smaller than these limits, the allocated Window will be resized up to at
least these sizes.

=head2 child_lines_max

=head2 set_child_lines_max

=head2 child_cols_max

=head2 set_child_cols_max

   $max = $box->child_lines_max

   $box->set_child_lines_max( $max )

   $max = $box->child_cols_max

   $box->set_child_cols_max( $max )

Accessors for the child size maximum limits. If the child widget requests a
size larger than these limits, the allocated Window will be resized down to at
most these sizes.

=head2 set_child_lines

=head2 set_child_cols

   $box->set_child_lines( $size )

   $box->set_child_cols( $size )

Convenient shortcut mutators that set both the minimum and maximum limit to
the same value. This has the effect of forcing the size of the child widget.

=cut

has $_child_lines_max; method _child_lines_max :lvalue { $_child_lines_max }
has $_child_lines_min; method _child_lines_min :lvalue { $_child_lines_min }
has $_child_cols_max;  method _child_cols_max  :lvalue { $_child_cols_max  }
has $_child_cols_min;  method _child_cols_min  :lvalue { $_child_cols_min  }

# Because I hate copying code 4 times
foreach my $dir (qw( lines cols )) {
   my %subs;

   foreach my $lim (qw( max min )) {
      my $slotmeth = "_child_${dir}_${lim}";
      my $name = "child_${dir}_${lim}";

      $subs{$name} = sub {
         my $self = shift;
         my $value = $self->$slotmeth;
         if( !defined $value ) {
            return undef;
         }
         elsif( $value =~ m/^(.+)%$/ ) {
            my $win = $self->window;
            return $win ? int( $1 * $win->$dir / 100 ) : undef;
         }
         else {
            return $value;
         }
      };

      $subs{"set_$name"} = sub {
         my $self = shift;
         ( $self->$slotmeth ) = @_;
         $self->resized;
      };
   }

   my $set_min = "set_child_${dir}_min";
   my $set_max = "set_child_${dir}_max";
   $subs{"set_child_$dir"} = sub {
      my $self = shift;
      my ( $value ) = @_;
      $self->$set_min( $value );
      $self->$set_max( $value );
   };

   no strict 'refs';
   *{$_} = $subs{$_} for keys %subs;
}

use Tickit::WidgetRole::Alignable name =>  "align", dir => "h", reshape => 1;
use Tickit::WidgetRole::Alignable name => "valign", dir => "v", reshape => 1;

method reshape
{
   my $window = $self->window or return;
   my $child  = $self->child or return;

   my ( $top, $lines ) = $self->_valign_allocation( $self->lines, $window->lines );
   my ( $left, $cols ) = $self->_align_allocation ( $self->cols,  $window->cols  );
   my @geom = ( $top, $left, $lines, $cols );

   if( my $childwin = $child->window ) {
      $childwin->change_geometry( @geom );
   }
   else {
      $child->set_window( $window->make_sub( @geom ) );
   }

   $self->redraw;
}

method window_lost
{
   my $child = $self->child or return;
   $child->set_window( undef );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
