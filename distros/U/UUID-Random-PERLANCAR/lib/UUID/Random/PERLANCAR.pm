package UUID::Random::PERLANCAR;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-20'; # DATE
our $DIST = 'UUID-Random-PERLANCAR'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

sub generate {
    sprintf(
        "%08x-%04x-%04x-%04x-%04x%08x",
        rand(2**32),
        rand(2**16),
        rand(2**16),
        rand(2**16),
        rand(2**16), rand(2**32),
    );
}

1;
# ABSTRACT: Another implementation of UUID::Random

__END__

=pod

=encoding UTF-8

=head1 NAME

UUID::Random::PERLANCAR - Another implementation of UUID::Random

=head1 VERSION

This document describes version 0.004 of UUID::Random::PERLANCAR (from Perl distribution UUID-Random-PERLANCAR), released on 2021-01-20.

=head1 SYNOPSIS

Use like you would L<UUID::Random>:

 use UUID::Random::PERLANCAR;
 say UUID::Random::PERLANCAR::generate();

=head1 DESCRIPTION

Note that this module does not produce RFC 4122-compliant v4 (random) UUIDs (no
encoding of variant and version information into the UUID).

=head1 FUNCTIONS

=head2 generate

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/UUID-Random-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-UUID-Random-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-UUID-Random-PERLANCAR/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<UUID::Random>

Benchmark in L<Acme::CPANModules::UUID>

L<Crypt::Misc>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
