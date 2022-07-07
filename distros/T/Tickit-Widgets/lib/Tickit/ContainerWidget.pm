#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2022 -- leonerd@leonerd.org.uk

use Object::Pad 0.57;

package Tickit::ContainerWidget 0.56;
class Tickit::ContainerWidget
   :isa(Tickit::Widget);

use Carp;

use Scalar::Util qw( refaddr );

=head1 NAME

C<Tickit::ContainerWidget> - abstract base class for widgets that contain
other widgets

=head1 SYNOPSIS

 TODO

=head1 DESCRIPTION

This class acts as an abstract base class for widgets that contain at leaast
one other widget object. It provides storage for a hash of "options"
associated with each child widget.

=head1 STYLE

The following style tags are used:

=over 4

=item :focus-child

Set whenever a child widget within the container has the input focus.

=back

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $widget = Tickit::ContainerWidget->new( %args )

Constructs a new C<Tickit::ContainerWidget> object. Must be called on a
subclass that implements the required methods; see the B<SUBCLASS METHODS>
section below.

=cut

has %_child_opts;

# This class should probably be a role
ADJUST
{
   my $class = ref $self;

   foreach my $method (qw( children )) {
      $class->can( $method ) or
         croak "$class cannot ->$method - do you subclass and implement it?";
   }
}

=head1 METHODS

=cut

=head2 add

   $widget->add( $child, %opts )

Sets the child widget's parent, stores the options for the child, and calls
the C<children_changed> method. The concrete implementation will have to
implement storage of this child widget.

Returns the container C<$widget> itself, for easy chaining.

=cut

method add
{
   my ( $child, %opts ) = @_;

   $child and $child->isa( "Tickit::Widget" ) or
      croak "Expected child to be a Tickit::Widget";

   $child->set_parent( $self );

   $_child_opts{refaddr $child} = \%opts;

   $self->children_changed;

   return $self;
}

=head2 remove

   $widget->remove( $child_or_index )

Removes the child widget's parent, and calls the C<children_changed> method.
The concrete implementation will have to remove this child from its storage.

Returns the container C<$widget> itself, for easy chaining.

=cut

method remove
{
   my ( $child ) = @_;

   $child->set_parent( undef );
   $child->window->close if $child->window;
   $child->set_window( undef );

   delete $_child_opts{refaddr $child};

   $self->children_changed;

   return $self;
}

=head2 child_opts

   %opts = $widget->child_opts( $child )

   $opts = $widget->child_opts( $child )

Returns the options currently set for the given child as a key/value list in
list context, or as a HASH reference in scalar context. The HASH reference in
scalar context is the actual hash used to store the options - modifications to
it will be preserved.

=cut

method child_opts
{
   my ( $child ) = @_;

   my $opts = $_child_opts{refaddr $child};
   return $opts if !wantarray;
   return %$opts;
}

=head2 set_child_opts

   $widget->set_child_opts( $child, %newopts )

Sets new options on the given child. Any options whose value is given as
C<undef> are deleted.

=cut

method set_child_opts
{
   my ( $child, %newopts ) = @_;

   my $opts = $_child_opts{refaddr $child};

   foreach ( keys %newopts ) {
      defined $newopts{$_} ? ( $opts->{$_} = $newopts{$_} ) : ( delete $opts->{$_} );
   }

   $self->children_changed;
}

method child_resized
{
   $self->reshape if $self->window;
   $self->resized;
}

method children_changed
{
   $self->reshape if $self->window;
   $self->resized;
}

method window_gained
{
   $self->SUPER::window_gained( @_ );

   $self->window->set_focus_child_notify( 1 );
}

method window_lost
{
   foreach my $child ( $self->children ) {
      my $childwin = $child->window;
      $childwin and $childwin->close;

      $child->set_window( undef );
   }

   $self->SUPER::window_lost( @_ );
}

method _on_win_focus
{
   my ( $win, $evtype, $childwin ) = @_;
   $self->SUPER::_on_win_focus( @_ );

   $self->set_style_tag( "focus-child" => $evtype ) if $childwin;
}

=head2 find_child

   $child = $widget->find_child( $how, $other, %args )

Returns a child widget. The C<$how> argument determines how this is done,
relative to the child widget given by C<$other>:

=over 4

=item first

The first child returned by C<children> (C<$other> is ignored)

=item last

The last child returned by C<children> (C<$other> is ignored)

=item before

The child widget just before C<$other> in the order given by C<children>

=item after

The child widget just after C<$other> in the order given by C<children>

=back

Takes the following named arguments:

=over 8

=item where => CODE

Optional. If defined, gives a filter function to filter the list of children
before searching for the required one. Will be invoked once per child, with
the child widget set as C<$_>; it should return a boolean value to indicate if
that child should be included in the search.

=back

=cut

method find_child
{
   my ( $how, $other, %args ) = @_;

   my $children = $args{children} // "children";
   my @children = $self->$children;
   if( my $where = $args{where} ) {
      @children = grep { defined $other and $_ == $other or $where->() } @children;
   }

   if( $how eq "first" ) {
      return $children[0];
   }
   elsif( $how eq "last" ) {
      return $children[-1];
   }
   elsif( $how eq "before" ) {
      $children[$_] == $other and return $children[$_-1] for 1 .. $#children;
      return undef;
   }
   elsif( $how eq "after" ) {
      $children[$_] == $other and return $children[$_+1] for 0 .. $#children-1;
      return undef;
   }
   else {
      croak "Unrecognised ->find_child mode '$how'";
   }
}

use constant CONTAINER_OR_FOCUSABLE => sub {
   $_->isa( "Tickit::ContainerWidget" ) or
      $_->window && $_->window->is_visible && $_->CAN_FOCUS
};

=head2 focus_next

   $widget->focus_next( $how, $other )

Moves the input focus to the next widget in the widget tree, by searching in
the direction given by C<$how> relative to the widget given by C<$other>
(which must be an immediate child of C<$widget>).

The direction C<$how> must be one of the following four values:

=over 4

=item first

=item last

Moves focus to the first or last child widget that can take focus. Recurses
into child widgets that are themselves containers. C<$other> is ignored.

=item after

=item before

Moves focus to the next or previous child widget in tree order from the one
given by C<$other>. Recurses into child widgets that are themselves
containers, and out into parent containers.

These searches will wrap around the widget tree; moving C<after> the last node
in the widget tree will move to the first, and vice versa.

=back

This differs from C<find_child> in that it performs a full tree search through
the widget tree, considering parents and children. If a C<before> or C<after>
search falls off the end of one node, it will recurse up to its parent and
search within the next child, and so on.

Usually this would be used via the widget itself:

 $self->parent->focus_next( $how => $self );

=cut

method focus_next
{
   my ( $how, $other ) = @_;

   # This tree search has the potential to loop infinitely, if there are no
   # focusable widgets at all. It would only do this if it cycles via the root
   # widget twice in a row. Technically we could detect it earlier, but that
   # is more difficult to arrange for
   my $done_root;

   my $next;

   my $children = $self->can( "children_for_focus" ) || "children";

   while(1) {
      $next = $self->find_child( $how, $other,
         where => CONTAINER_OR_FOCUSABLE,
         children => $children,
      );
      last if $next and $next->CAN_FOCUS;

      # Either we found a container (recurse into it),
      if( $next ) {
         my $childhow = $how;
         if(    $how eq "after"  ) { $childhow = "first" }
         elsif( $how eq "before" ) { $childhow = "last" }

         # See if child has it
         return 1 if $next->focus_next( $childhow => undef );

         $other = $next;
         redo;
      }
      # or we'll have to recurse up to my parent
      elsif( my $parent = $self->parent ) {
         if( $how eq "after" or $how eq "before" ) {
            $other = $self;
            $self = $parent;
            redo;
         }
         else {
            return undef;
         }
      }
      # or we'll have to cycle around the root
      else {
         die "Cycled through the entire widget tree and did not find a focusable widget" if $done_root;
         $done_root++;

         if(    $how eq "after"  ) { $how = "first" }
         elsif( $how eq "before" ) { $how = "last"  }
         else { die "Cannot cycle how=$how around root widget"; }

         $other = undef;
         redo;
      }
   }

   $next->take_focus;
   return 1;
}

=head1 SUBCLASS METHODS

=head2 children

   @children = $widget->children

Required. Should return a list of all the contained child widgets. The order
is not specified, but should be in some stable order that makes sense given
the layout of the widget's children.

This method is used by C<window_lost> to remove the windows from all the child
widgets automatically, and by C<find_child> to obtain a child relative to
another given one.

=head2 children_for_focus

   @children = $widget->children_for_focus

Optional. If implemented, this method is called to obtain a list of child
widgets to perform a child search on when changing focus using the
C<focus_next> method. If it is not implemented, the regular C<children> method
is called instead.

Normally this method shouldn't be used, but it may be useful on container
widgets that also display "helper" widgets that should not be considered as
part of the main focus set. This method can then exclude them.

=head2 children_changed

   $widget->children_changed

Optional. If implemented, this method will be called after any change of the
contained child widgets or their options. Typically this will be used to set
windows on them by sub-dividing the window of the parent.

If not overridden, the base implementation will call C<reshape>.

=head2 child_resized

   $widget->child_resized( $child )

Optional. If implemented, this method will be called after a child widget
changes or may have changed its size requirements. Typically this will be used
to adjusts the windows allocated to children.

If not overridden, the base implementation will call C<reshape>.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
