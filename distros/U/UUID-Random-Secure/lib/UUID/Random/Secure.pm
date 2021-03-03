package UUID::Random::Secure;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-17'; # DATE
our $DIST = 'UUID-Random-Secure'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Math::Random::Secure qw(irand);

sub generate {
    sprintf(
        "%08x-%04x-%04x-%04x-%04x%08x",
        irand(),
        irand(2**16),
        irand(2**16),
        irand(2**16),
        irand(2**16),
        irand(),
    );
}

1;
# ABSTRACT: Like UUID::Random, but uses Math::Random::Secure for random numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

UUID::Random::Secure - Like UUID::Random, but uses Math::Random::Secure for random numbers

=head1 VERSION

This document describes version 0.001 of UUID::Random::Secure (from Perl distribution UUID-Random-Secure), released on 2021-01-17.

=head1 SYNOPSIS

Use like you would L<UUID::Random>:

 use UUID::Random::Secure;
 say UUID::Random::Secure::generate();

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 generate

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/UUID-Random-Secure>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-UUID-Random-Secure>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-UUID-Random-Secure/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<UUID::Random>

L<Math::Random::Secure>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
