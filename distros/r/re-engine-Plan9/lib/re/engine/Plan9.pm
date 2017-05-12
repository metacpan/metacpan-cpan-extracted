package re::engine::Plan9;
BEGIN {
  $re::engine::Plan9::VERSION = '0.16';
}
use 5.010;
use XSLoader ();

# All engines should subclass the core Regexp package
our @ISA = 'Regexp';

BEGIN
{
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

re::engine::Plan9 - Plan 9 regular expression engine

=head1 SYNOPSIS

    use re::engine::Plan9;

    if ("bewb" =~ /(.)(.)/) {
        print $1; # b
        print $2; # e
        print $'; # wb
    }

=head1 DESCRIPTION

Replaces perl's regex engine in a given lexical scope with Plan 9
regular expression provided by libregexp9. libregexp9 and the libfmt
and libutf it depends on from Plan 9 are shipped with the module.

The C</s> modifier causes C<.> to match a newline (C<regcompnl>) and
the C</x> modifier allegedly causes all characters to be treated
literally (C<regcomplit>), see regexp9(3). The engine will C<croak> if
it's given other modifier.

If an invalid pattern is supplied perl will die with an error from
regerror(3).

=head1 CAVEATS

The Plan 9 engine only supports 32 capture buffers, consequently match
variables only go up to C<$31> (C<$&> is number zero).

=head1 SEE ALSO

=over 4

=item regexp9(7) - Plan 9 regular expression notation

L<http://swtch.com/plan9port/unix/man/regexp97.html>

=item regexp9(3) - regcomp, regexec etc.

L<http://swtch.com/plan9port/unix/man/regexp93.html>

=item Unix Software from Plan 9

L<http://swtch.com/plan9port/unix/>

=back

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE

Copyright 2007 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The included libutf, libfmt and libregexp9 libraries are provided
under the following license:

    The authors of this software are Rob Pike and Ken Thompson.
                 Copyright (c) 2002 by Lucent Technologies.
    Permission to use, copy, modify, and distribute this software for any
    purpose without fee is hereby granted, provided that this entire notice
    is included in all copies of any software which is or includes a copy
    or modification of this software and in all copies of the supporting
    documentation for such software.
    THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
    WARRANTY.  IN PARTICULAR, NEITHER THE AUTHORS NOR LUCENT TECHNOLOGIES MAKE ANY
    REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
    OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.

=cut
