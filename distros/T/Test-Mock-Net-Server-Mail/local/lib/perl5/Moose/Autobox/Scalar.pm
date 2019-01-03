package Moose::Autobox::Scalar;
# ABSTRACT: the Scalar role
use Moose::Role 'with';
use namespace::autoclean;

our $VERSION = '0.16';

with 'Moose::Autobox::String',
     'Moose::Autobox::Number';

sub flatten { $_[0] }
sub first { $_[0] }
sub last  { $_[0] }
sub print { CORE::print $_[0] }
sub say   { CORE::print $_[0], "\n" }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::Scalar - the Scalar role

=head1 VERSION

version 0.16

=head1 DESCRIPTION

This is a role to describes a Scalar value, which is defined
as the combination (union sort of) of a String and a Number.

=head1 METHODS

=over 4

=item C<meta>

=item C<print>

=item C<say>

=item C<flatten>

Flattening a scalar just returns the scalar.  This means that you can say:

  my @array = $input->flatten;

  # Given $input of 5, @array is (5);
  # Given $input of [ 5, 2, 0], @array is (5, 2, 0)

=item C<first>

As per flatten.

=item C<last>

As per flatten.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Moose-Autobox>
(or L<bug-Moose-Autobox@rt.cpan.org|mailto:bug-Moose-Autobox@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
