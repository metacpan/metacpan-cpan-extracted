package Moose::Autobox::Indexed;
# ABSTRACT: the Indexed role
use Moose::Role 'requires';
use namespace::autoclean;

our $VERSION = '0.16';

requires 'at';
requires 'put';
requires 'exists';
requires 'keys';
requires 'values';
requires 'kv';
requires 'slice';
requires qw(each each_key each_value each_n_values);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::Indexed - the Indexed role

=head1 VERSION

version 0.16

=head1 DESCRIPTION

This is a role to describes an collection whose values can be
accessed by a key of some kind.

The role is entirely abstract, those which implement it must
supply all it's methods. Currently both L<Moose::Autobox::Array>
and L<Moose::Autobox::Hash> implement this role.

=head1 METHODS

=over 4

=item C<meta>

=back

=head1 REQUIRED METHODS

=over 4

=item C<at>

=item C<put>

=item C<exists>

=item C<keys>

=item C<values>

=item C<kv>

=item C<slice>

=item C<each>

=item C<each_key>

=item C<each_value>

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
