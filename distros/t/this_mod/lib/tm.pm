## no critic: TestingAndDebugging::RequireUseStrict
package tm;
use alias::module 'this_mod';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-06'; # DATE
our $DIST = 'this_mod'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Shorter alias for this_mod.pm

__END__

=pod

=encoding UTF-8

=head1 NAME

tm - Shorter alias for this_mod.pm

=head1 VERSION

This document describes version 0.001 of tm (from Perl distribution this_mod), released on 2024-01-06.

=head1 SYNOPSIS

 % pwd
 perl-File-Util-Symlink

 % perl -Ilib -Mthis_mod=symlink_rel -E'symlink_rel(..., ...)'; # loading 'this_mod' will load File::Util::Symlink instead
 % perl -Ilib -Mtm=symlink_rel       -E'symlink_rel(..., ...)'; # loading 'this_mod' will load File::Util::Symlink instead

=head1 DESCRIPTION

See L<this_mod>.pm.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/this_mod>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-this_mod>.

=head1 SEE ALSO

L<this_mod>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=this_mod>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
