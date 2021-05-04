package UUID::Random::Patch::UseMRS;

our $VERSION = '0.02'; # VERSION

require Math::Random::Secure;

# testing
#*UUID::Random::rand = sub { die };

*UUID::Random::rand = \&Math::Random::Secure::rand;

require UUID::Random;

1;
# ABSTRACT: Make UUID::Random use Math::Random::Secure's rand()

__END__

=pod

=encoding UTF-8

=head1 NAME

UUID::Random::Patch::UseMRS - Make UUID::Random use Math::Random::Secure's rand()

=head1 VERSION

This document describes version 0.02 of UUID::Random::Patch::UseMRS (from Perl distribution UUID-Random-Patch-UseMRS), released on 2021-01-24.

=head1 SYNOPSIS

 use UUID::Random::Patch::UseMRS;
 say UUID::Random::generate();

=head1 DESCRIPTION

This module makes L<UUID::Random> use C<rand()> from L<Math::Random::Secure>
instead of the default C<rand()> that comes with Perl. It is useful for creating
cryptographically secure UUID's. On the other hand, as a note, this makes
generate() around 20 times slower on my PC.

After you C<use> this module, use UUID::Random as usual.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/UUID-Random-Patch-UseMRS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-UUID-Random-Patch-UseMRS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-UUID-Random-Patch-UseMRS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Math::Random::Secure>, L<UUID::Random>.

Other ways to generate cryptographically secure random (v4) UUIDs:
L<Crypt::Misc>, L<UUID::Random::Secure>, L<UUID::Tiny::Patch::UseMRS> and
L<UUID::Tiny>. L<Acme::CPANModules::UUID> contains reviews and benchmarks of
these.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
