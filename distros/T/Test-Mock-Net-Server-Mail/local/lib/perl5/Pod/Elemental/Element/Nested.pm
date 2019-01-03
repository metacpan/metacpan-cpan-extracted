package Pod::Elemental::Element::Nested;
# ABSTRACT: an element that is a command and a node
$Pod::Elemental::Element::Nested::VERSION = '0.103004';
use Moose;
extends 'Pod::Elemental::Element::Generic::Command';
with 'Pod::Elemental::Node';
with 'Pod::Elemental::Autochomp';

use namespace::autoclean;

# BEGIN Autochomp Replacement
use Pod::Elemental::Types qw(ChompedString);
has '+content' => (coerce => 1, isa => ChompedString);
# END   Autochomp Replacement

#pod =head1 WARNING
#pod
#pod This class is somewhat sketchy and may be refactored somewhat in the future,
#pod specifically to refactor its similarities to
#pod L<Pod::Elemental::Element::Pod5::Region>.
#pod
#pod =head1 OVERVIEW
#pod
#pod A Nested element is a Generic::Command element that is also a node.
#pod
#pod It's used by the nester transformer to produce commands with children, to make
#pod documents seem more structured for easy manipulation.
#pod
#pod =cut

override as_pod_string => sub {
  my ($self) = @_;

  my $string = super;

  $string = join q{},
    "$string\n\n",
    map { $_->as_pod_string } @{ $self->children };

  $string =~ s/\n{3,}\z/\n\n/g;

  return $string;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Nested - an element that is a command and a node

=head1 VERSION

version 0.103004

=head1 OVERVIEW

A Nested element is a Generic::Command element that is also a node.

It's used by the nester transformer to produce commands with children, to make
documents seem more structured for easy manipulation.

=head1 WARNING

This class is somewhat sketchy and may be refactored somewhat in the future,
specifically to refactor its similarities to
L<Pod::Elemental::Element::Pod5::Region>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
