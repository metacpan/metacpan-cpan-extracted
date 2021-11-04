package Tree::ObjectXS;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'Tree-ObjectXS'; # DIST
our $VERSION = '0.030'; # VERSION

1;
# ABSTRACT: Generic tree objects (with XS accessors, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::ObjectXS - Generic tree objects (with XS accessors, etc)

=head1 VERSION

This document describes version 0.030 of Tree::ObjectXS (from Perl distribution Tree-ObjectXS), released on 2021-10-07.

=head1 DESCRIPTION

This distribution provides several implementations of tree classes (and class
generators) which you can use directly or as a base class. All of them consume
the roles from L<RoleBundle::TinyCommons::Tree> distribution.

Provided classes:

=over

=item * L<Tree::ObjectXS::Array>

=item * L<Tree::ObjectXS::Hash>

=back

The modules are just like their counterpart in the L<Tree::ObjectXS>
distribution, except that XS optimized modules/codes are used. The modules are
separated into this distribution because they depend on XS modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-ObjectXS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-ObjectXS>.

=head1 SEE ALSO

L<Tree::Object>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-ObjectXS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
