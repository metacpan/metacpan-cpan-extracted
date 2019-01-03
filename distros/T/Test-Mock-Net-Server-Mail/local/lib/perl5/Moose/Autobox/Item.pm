package Moose::Autobox::Item;
# ABSTRACT: the Item role
use Moose::Role 'requires';
use namespace::autoclean;

our $VERSION = '0.16';

requires 'defined';

sub dump {
    my $self = shift;
    require Data::Dumper;
    return Data::Dumper::Dumper($self);
}

*perl = \&dump;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::Item - the Item role

=head1 VERSION

version 0.16

=head1 DESCRIPTION

This is the root of our role hierarchy.

=head1 METHODS

=over 4

=item C<meta>

=item C<dump>

Calls Data::Dumper::Dumper.

=item C<perl>

Same as C<dump>. For symmetry with Perl6's .perl method.

Like &print with newline.

=item C<print2>

=back

=head1 REQUIRED METHODS

=over 4

=item C<defined>

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
