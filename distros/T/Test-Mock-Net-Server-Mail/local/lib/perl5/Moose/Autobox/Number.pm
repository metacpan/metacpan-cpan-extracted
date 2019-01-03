package Moose::Autobox::Number;
# ABSTRACT: Moose::Autobox::Number - the Number role
use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.16';

with 'Moose::Autobox::Value';

sub to {
    return [ $_[0] .. $_[1] ] if $_[0] <= $_[1];
    return [ reverse $_[1] .. $_[0] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::Number - Moose::Autobox::Number - the Number role

=head1 VERSION

version 0.16

=head1 DESCRIPTION

This is a role to describes a Numeric value.

=head1 METHODS

=over 4

=item C<to>

Takes another number as argument and produces an array ranging from
the number the method is called on to the number given as argument. In
some situations, this method intentionally behaves different from the
range operator in perl:

  $foo = [ 5 .. 1 ]; # $foo is []

  $foo = 5->to(1);   # $foo is [ 5, 4, 3, 2, 1 ]

=back

=over 4

=item C<meta>

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
