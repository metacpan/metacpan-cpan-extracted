package re::engine::LPEG;
use 5.010000;
use XSLoader ();

# All engines should subclass the core Regexp package
our @ISA = 'Regexp';

BEGIN
{
    $VERSION = '0.05';
    XSLoader::load __PACKAGE__, $VERSION;
}

sub import
{
    $^H{regcomp} = ENGINE;
}

sub unimport
{
    delete $^H{regcomp}
        if $^H{regcomp} == ENGINE;
}

1;

__END__

=head1 NAME

re::engine::LPEG - LPEG regular expression engine

=head1 SYNOPSIS

    use re::engine::LPEG;

    if ('Hello, world' =~ m{ ( 'Hello' / 'Hi' ) ', ' { 'world' } });
        print "Greetings, $1!";
    }

=head1 DESCRIPTION

THIS MODULE IS A FAILURE.
THE re-engine INTERFACE IS NOT THE RIGHT WAY TO WRAP LPeg.

Replaces perl's regex engine in a given lexical scope with the LPeg one.

See "Regex syntax for LPEG", on
L<http://www.inf.puc-rio.br/~roberto/lpeg/re.html>.

=head2 Common Pitfalls

=over 4

=item *

Literal string must be quoted or double quoted.
Spaces are not significatives.

=item *

LPeg works only in I<anchored> mode.
So LPeg is unusable with C<split>, and not suitable for C<s///>.

=item *

C<'/'> represents an ordered choice, so the syntax C<'m{pattern}'> is more
readeable than C<'/pattern/'> where C<'/'> must be escaped.

=item *

Pre-defined character classes start by C<'%'> (like in the Lua string library).
See L<http://www.lua.org/manual/5.1/manual.html#5.4.1>.

=back

=head1 AUTHORS

FranE<ccedil>ois PERRAD <francois.perrad@gadz.org>

=head1 HOMEPAGE

The development is hosted at L<http://code.google.com/p/re-engine-lpeg/>.

=head1 COPYRIGHT

Copyright 2008 FranE<ccedil>ois PERRAD.

This program is free software; you can redistribute it and/or modify it
under the same terms as Lua & LPeg, see L<http://www.lua.org/license.html>.

=cut

