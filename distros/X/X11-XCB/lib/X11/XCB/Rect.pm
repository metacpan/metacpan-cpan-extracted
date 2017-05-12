=head1 NAME

X11::XCB::Rect - represents a rectangle

=head1 SYNOPSIS

  my $rect = X11::XCB::Rect->new(x => 0, y => 0, width => 300, height => 400);

But in most cases, you should be able to coerce a rect from an arrayref:

  my $window = $x->root->create_child(
    rect => [0, 0, 300, 300],
    class => WINDOW_CLASS_INPUT_OUTPUT,
  );

=cut
package X11::XCB::Rect;

use Mouse;
use Mouse::Util::TypeConstraints;

coerce 'X11::XCB::Rect'
    => from 'ArrayRef'
    => via { X11::XCB::Rect->new(x => $_->[0], y => $_->[1], width => $_->[2], height => $_->[3]) };

has [ qw(x y width height) ] => (is => 'ro', isa => 'Int', required => 1);

1
# vim:ts=4:sw=4:expandtab
