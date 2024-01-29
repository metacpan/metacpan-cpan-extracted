## no critic: TestingAndDebugging::RequireUseStrict
package Tie::Hash::NoOp;

# IFUNBUILT
# use strict;
# END IFUNBUILT

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-27'; # DATE
our $DIST = 'Tie-Hash-NoOp'; # DIST
our $VERSION = '0.001'; # VERSION

sub TIEHASH {
    my $class = shift;

    bless [], $class;
}

sub FETCH {}

sub STORE {}

sub DELETE {}

sub CLEAR {}

sub EXISTS {}

sub FIRSTKEY {}

sub NEXTKEY {}

sub SCALAR {0}

sub UNTIE {}

# DESTROY

1;
# ABSTRACT: Tied hash that does nothing

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Hash::NoOp - Tied hash that does nothing

=head1 VERSION

This document describes version 0.001 of Tie::Hash::NoOp (from Perl distribution Tie-Hash-NoOp), released on 2023-12-27.

=head1 SYNOPSIS

 use Tie::Hash::NoOp;

 tie my %hash, 'Tie::Hash::NoOp';

=head1 DESCRIPTION

This class implements a tied hash that does nothing. For benchmark purposes.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Hash-NoOp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Hash-NoOp>.

=head1 SEE ALSO

L<perltie>

Other C<Tie::*::NoOp>

L<Bencher::Scenarios::Tie>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Hash-NoOp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
