package UUID::Tiny::Patch::UseMRS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-24'; # DATE
our $DIST = 'UUID-Tiny-Patch-UseMRS'; # DIST
our $VERSION = '0.002'; # VERSION

require Math::Random::Secure;

# testing
#*UUID::Tiny::rand = sub { die };

*UUID::Tiny::rand = \&Math::Random::Secure::rand;

require UUID::Tiny;

1;
# ABSTRACT: Make UUID::Tiny use Math::Random::Secure's rand()

__END__

=pod

=encoding UTF-8

=head1 NAME

UUID::Tiny::Patch::UseMRS - Make UUID::Tiny use Math::Random::Secure's rand()

=head1 VERSION

This document describes version 0.002 of UUID::Tiny::Patch::UseMRS (from Perl distribution UUID-Tiny-Patch-UseMRS), released on 2021-01-24.

=head1 SYNOPSIS

 use UUID::Tiny::Patch::UseMRS;
 say UUID::Tiny::create_uuid();

=head1 DESCRIPTION

This module makes L<UUID::Tiny> use C<rand()> from L<Math::Random::Secure>
instead of the default C<rand()> that comes with Perl. It is useful for creating
cryptographically secure UUID's. On the other hand, as a note, this makes
generate() around 3 times slower on my Dell XPS 13 laptop.

After you C<use> this module, use UUID::Tiny as usual.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/UUID-Tiny-Patch-UseMRS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-UUID-Tiny-Patch-UseMRS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-UUID-Tiny-Patch-UseMRS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Math::Random::Secure>, L<UUID::Tiny>

Other ways to generate random (v4) UUIDs: L<Crypt::Misc>,
L<UUID::Random::Secure>, L<UUID::Random::Patch::UseMRS> and L<UUID::Random>.
L<Acme::CPANModules::UUID> contains reviews and benchmarks of these.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
