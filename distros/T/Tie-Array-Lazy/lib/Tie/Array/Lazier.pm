package Tie::Array::Lazier;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;
use base 'Tie::Array::Lazy';

sub EXTEND($$) { } # does nothing

sub FETCH($$) {
    my ( $self, $index ) = @_;
    $self->array->[$index] = $self->maker->($self, $index)
	unless exists $self->array->[$index];
    $self->array->[$index];
}

sub STORE($$$) {
    my ( $self, $index, $value ) = @_;
    $self->array->[$index] = $value;
}

1;
__END__

=head1 NAME

Tie::Array::Lazier - Lazier than Tie::Array::Lazy

=head1 VERSION

$Id: Lazier.pm,v 0.2 2012/08/09 19:07:27 dankogai Exp $

=cut

=head1 SYNOPSIS

  use Tie::Array::Laier;
  # 0..Inf
  tie my @a, 'Tie::Array::Laier', [], sub{ $_[1] };
  $a[3] = 'three'; # $self->array is [undef, undef, undef, 'three']
  print "$_\n" for @a; # 0, 1, 2, 'three', 4 ...

=head1 DESCRIPTION

L<Tie::Array::Lazier> is a child class of L<Tie::Array::Lazy> that
behaves a lot like its parent except for one thing; It is even lazier.

Instead of filling elements up to C<$index>, L<Tie::Array::Lazier> It
calls C<< $self->maker >> when C<< $self->array->[$index] >> is undef.
Therefore you cannot store undef to the tied array.

=head1 EXPORT

None.

=head1 FUNCTIONS

Same as L<Tie::Array::Lazy>.

=head2 note on $_[0]->index vs $_[1]

While C<< $_[0]->index >> is identical to C<$_[1]> in
L<Tie::Array::Lazy>>, these values may disagree in
L<Tie::Array::Lazier> Whenever you need the index, use C<$_[1]>.

  # 0..Inf
  tie my @a, 'Tie::Array::Lazier', [], sub{ $_[0]->index }; # wrong!
  tie my @a, 'Tie::Array::Lazier', [], sub{ $_[1] };        # right!

You can still use C<< $_[0]->index >> to find how many elements the
internal array holds.

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

See L<Tie::Array::Lazy>.

=head1 SUPPORT

See L<Tie::Array::Lazy>.

=head1 ACKNOWLEDGEMENTS

See L<Tie::Array::Lazy>.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
