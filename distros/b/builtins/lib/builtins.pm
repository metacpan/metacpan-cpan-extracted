package builtins;

use 5.036;
use warnings;

our $VERSION = '0.000005';

sub import {
    warnings->unimport('experimental::builtin');
    builtin->import( grep { $_ ne 'import' } keys %builtin:: );
}


1; # Magic true value required at end of module
__END__

=head1 NAME

builtins - Install all the new builtins from the C<builtin> namespace


=head1 VERSION

This document describes C<builtins> version 0.000001


=head1 SYNOPSIS

    use v5.36;     # Or later
    use builtins;  # Loads all new builtins into lexical scope

    # So now we can write...
    if (reftype($x) eq 'ARRAY' || blessed($x) {
        say refaddr($x);
        if (is_weak($x)) {
            unweaken($x);
            say ceil( refaddr(($x)) / floor($y) );
            weaken($x);
            say trim($description);
        }
    }



=head1 DESCRIPTION

Perl 5.36 introduced numerous new built-in functions to the core.
Unfortunately, for backwards compatibility, none of them are
automatically available. And all of them are still experimental.

Which means, if you want them all, you have to preface your code with:

    use experimental 'builtin';
    use builtin qw(
        ceil    floor     trim
        true    false     is_bool
        weaken  unweaken  is_weak
        blessed refaddr   reftype   indexed
        created_as_string created_as_number
    );

Or you can use this module and get the same effect with just:

    use builtins;


=head1 INTERFACE

None.

You simply use the module and it takes care of installing every available
C<builtin> built-in into the current lexical scope (just like a S<C<use builtin qw(...)>> would).
It also turns off the "experimental" warnings about each built-in it installs.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

C<builtins> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<builtins> requires Perl 5.36 or later.
It has no other dependencies.

=head1 INCOMPATIBILITIES

None reported.

It is specifically compatible with C<builtin>, so you can
still S<C<use builtins>> if you've already said S<C<use builtin>>
(and vice versa).


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-builtins@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2022, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
