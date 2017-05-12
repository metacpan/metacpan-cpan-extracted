use strict;
use warnings;
package me::inlined; # git description: v0.003-17-gfc99405
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: EXPERIMENTAL - define multiple packages in one file, and reference them in any order
# KEYWORDS: development module package file inline declaration

our $VERSION = '0.004';

use Module::Runtime ();

sub import
{
    my $self = shift;
    my ($caller, $caller_file) = caller;
    my $filename = Module::Runtime::module_notional_filename($caller);
    $::INC{$filename} = $caller_file;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

me::inlined - EXPERIMENTAL - define multiple packages in one file, and reference them in any order

=head1 VERSION

version 0.004

=head1 SYNOPSIS

before:

    package Foo;

    package Bar;
    use Foo;                        # kaboom: "Can't locate Foo.pm in @INC"

after:

    package Foo;
    use me::inlined;

    package Bar;
    use Foo;                        # no kaboom!

=head1 DESCRIPTION

If you've ever defined multiple packages in the same file, but want to C<use>
one package in another, you'll have discovered why it's much
easier to simply follow best practices and define one package per file.

However, this module will let you minimize your inode usage:
simply add C<< use me::inlined >> in any package that you want to refer to in
other namespaces in the same file, and you can
(probably) safely define and use packages in any order.

This will also let you do C<< require Foo; >> in other code, after the F<.pm>
file containing C<Foo> has been loaded, without C<require> complaining that
it cannot find F<Foo.pm> in C<@INC>.

This module is for demonstration purposes only, and in no way am I
recommending you use this in any real code whatsoever.

=head1 FUNCTIONS/METHODS

There is no public API other than the C<use> directive itself, which takes no
arguments.

=head1 CAVEATS

There may be edge cases where this doesn't work right, or leads to infinite
looping when trying to compile modules. Use at your own risk!

=head1 ACKNOWLEDGEMENTS

This module was inspired by a conversation witnessed on C<modules@perl.org> --
credit for the idea belongs to L<Linda Walsh|https://metacpan.org/author/LAWALSH>.

=head1 SEE ALSO

=over 4

=item *

L<mem>

=item *

L<thanks>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=me-inlined>
(or L<bug-me-inlined@rt.cpan.org|mailto:bug-me-inlined@rt.cpan.org>).

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Neil Bowers

Neil Bowers <neil@bowers.com>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
