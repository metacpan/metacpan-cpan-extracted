package VS::Chart::Color::Gradient;

use strict;
use warnings;

sub new {
    my ($pkg, $c1, $c2) = @_;
    my $self = bless [$c1, $c2], $pkg;
    return $self;
}

sub set {
    my ($self, $cx, $surface, $width, $height) = @_;
    
    my $gr = Cairo::LinearGradient->create(0, 0, 0, $height);
    $gr->add_color_stop_rgba(0, @{$self->[0]});
    $gr->add_color_stop_rgba(1, @{$self->[1]});
    
    $cx->set_source($gr);
}

1;
__END__

=head1 NAME

VS::Chart::Color::Gradient - A gradient color.

=head1 DESCRIPTION

This color renders as a gradient from one color to the other. First color is positioned at the top of 
the image and the second on the bottom.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( COLOR, COLOR )

Creates a new gradient from COLOR to COLOR.

=back

=head2 INSTANCE METHODS

=over 4

=item set ( CONTEXT, SURFACE, WIDTH, HEIGHT )

Sets the the context to use this color.

=back

=cut
