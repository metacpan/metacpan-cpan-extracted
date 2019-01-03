package Moose::Autobox; # git description: 0_09-64-ge6e9586
# ABSTRACT: Autoboxed wrappers for Native Perl datatypes
use 5.006;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Moose::Util  ();

our $VERSION = '0.16';

use parent 'autobox';

use Moose::Autobox::Undef;

sub import {
    (shift)->SUPER::import(
        DEFAULT => 'Moose::Autobox::',
        UNDEF   => 'Moose::Autobox::Undef',
    );
}

sub mixin_additional_role {
    my ($class, $type, $role) = @_;
    ($type =~ /SCALAR|ARRAY|HASH|CODE/)
        || Carp::confess "Can only add additional roles to SCALAR, ARRAY, HASH or CODE";
    Moose::Util::apply_all_roles(('Moose::Autobox::' . $type)->meta, ($role));
}

{
    package
      Moose::Autobox::SCALAR;

    use Moose::Autobox::Scalar;

    use metaclass 'Moose::Meta::Class';

    Moose::Util::apply_all_roles(__PACKAGE__->meta, ('Moose::Autobox::Scalar'));

    *does = \&Moose::Object::does;

    package
      Moose::Autobox::ARRAY;

    use Moose::Autobox::Array;

    use metaclass 'Moose::Meta::Class';

    Moose::Util::apply_all_roles(__PACKAGE__->meta, ('Moose::Autobox::Array'));

    *does = \&Moose::Object::does;

    package
      Moose::Autobox::HASH;

    use Moose::Autobox::Hash;

    use metaclass 'Moose::Meta::Class';

    Moose::Util::apply_all_roles(__PACKAGE__->meta, ('Moose::Autobox::Hash'));

    *does = \&Moose::Object::does;

    package
      Moose::Autobox::CODE;

    use Moose::Autobox::Code;

    use metaclass 'Moose::Meta::Class';

    Moose::Util::apply_all_roles(__PACKAGE__->meta, ('Moose::Autobox::Code'));

    *does = \&Moose::Object::does;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Autoboxed autobox

=head1 NAME

Moose::Autobox - Autoboxed wrappers for Native Perl datatypes

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  use Moose::Autobox;

  print 'Print squares from 1 to 10 : ';
  print [ 1 .. 10 ]->map(sub { $_ * $_ })->join(', ');

=head1 DESCRIPTION

Moose::Autobox provides an implementation of SCALAR, ARRAY, HASH
& CODE for use with L<autobox>. It does this using a hierarchy of
roles in a manner similar to what Perl 6 I<might> do. This module,
like L<Class::MOP> and L<Moose>, was inspired by my work on the
Perl 6 Object Space, and the 'core types' implemented there.

=head2 A quick word about autobox

The L<autobox> module provides the ability for calling 'methods'
on normal Perl values like Scalars, Arrays, Hashes and Code
references. This gives the illusion that Perl's types are first-class
objects. However, this is only an illusion, albeit a very nice one.
I created this module because L<autobox> itself does not actually
provide an implementation for the Perl types but instead only provides
the 'hooks' for others to add implementation too.

=head2 Is this for real? or just play?

Several people are using this module in serious applications and
it seems to be quite stable. The underlying technologies of L<autobox>
and L<Moose::Role> are also considered stable. There is some performance
hit, but as I am fond of saying, nothing in life is free.  Note that this hit
only applies to the I<use> of methods on native Perl values, not the mere act
of loading this module in your namespace.

If you have any questions regarding this module, either email me, or stop by
#moose on irc.perl.org and ask around.

=head2 Adding additional methods

B<Moose::Autobox> asks L<autobox> to use the B<Moose::Autobox::*> namespace
prefix so as to avoid stepping on the toes of other L<autobox> modules. This
means that if you want to add methods to a particular perl type
(i.e. - monkeypatch), then you must do this:

  sub Moose::Autobox::SCALAR::bar { 42 }

instead of this:

  sub SCALAR::bar { 42 }

as you would with vanilla autobox.

=head1 METHODS

=over 4

=item C<mixin_additional_role ($type, $role)>

This will mixin an additional C<$role> into a certain C<$type>. The
types can be SCALAR, ARRAY, HASH or CODE.

This can be used to add additional methods to the types, see the
F<examples/units/> directory for some examples.

=back

=for :stopwords TODO

=head1 TODO

=over 4

=item More docs

=item More tests

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

=head1 CONTRIBUTORS

=for stopwords Ricardo Signes Karen Etheridge Anders Nor Berle Matt S Trout Steffen Schwigon Michael Swearingen Florian Ragwitz Jonathan Rockway Shawn M Moore Todd Hepler David Steinbrunner Mike Whitaker Nigel Gregoire

=over 4

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Anders Nor Berle <berle@cpan.org>

=item *

Matt S Trout <mst@shadowcat.co.uk>

=item *

Steffen Schwigon <ss5@renormalist.net>

=item *

Michael Swearingen <mswearingen@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jonathan Rockway <jon@jrock.us>

=item *

Shawn M Moore <sartak@gmail.com>

=item *

Todd Hepler <thepler@employees.org>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Mike Whitaker <mike@altrion.org>

=item *

Nigel Gregoire <nigelgregoire@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
