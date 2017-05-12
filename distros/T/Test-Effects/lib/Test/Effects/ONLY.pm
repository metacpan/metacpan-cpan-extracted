package Test::Effects::ONLY;

no if $] >= 5.018, 'warnings', "experimental";
use 5.014;
use warnings;

our $VERSION = '0.000001';

sub import   { $^H{'Test::Effects::ONLY'} = 1; }
sub unimport { $^H{'Test::Effects::ONLY'} = 0; }


1; # Magic true value required at end of module
__END__

=head1 NAME

Test::Effects::ONLY - Lexically set Test::Effects verbosity


=head1 VERSION

This document describes Test::Effects::ONLY version 0.000001


=head1 SYNOPSIS

    {
        use Test::Effects::ONLY;
        # Test::Effects defaults to only testing specified effects in this scope

        {
            no Test::Effects::ONLY;
            # Test::Effects defaults to testing all effects in this scope
        }

        # Test::Effects still only testing specified effects here

    }
    # Test::Effects reverts to original behaviour here


=head1 DESCRIPTION

Using this module changes the default behaviour of Test::Effects's
C<effects_ok()> test.

Normally this test tests all side-effects, even those unspecified
(unless explicitly told otherwise via the use of C<ONLY()>). If this
module is used in a code block, C<effects_ok()> defaults to only running
specified tests for the remainder of that block's lexical scope.

Note, however, that an explicit C<< ONLY => $boolean >> option in
any call to C<<effects_ok()> overrides this lexical default.

=head1 INTERFACE 

=head2 C<use Test::Effects::ONLY;>

C<effects_ok> defaults to only runnign specified test within the rest of
the current lexical scope.


=head2 C<no Test::Effects::ONLY;>

C<effects_ok> defaults to running all tests (including unspecified ones)
within the rest of the current lexical scope.


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

Test::Effects::ONLY requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires Perl 5.14 (or better).

Does not require, but is meaningless without, the Test::Effects module.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-lib-test-effects@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

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
