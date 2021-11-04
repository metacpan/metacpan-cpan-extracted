package Tree::ObjectXS::Hash;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'Tree-ObjectXS'; # DIST
our $VERSION = '0.030'; # VERSION

use Class::XSAccessor {
    constructor => 'new',
    accessors   => ['parent', 'children'],
};

use Role::Tiny::With;
with 'Role::TinyCommons::Tree::NodeMethods';

1;
# ABSTRACT: A hash-based tree object

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::ObjectXS::Hash - A hash-based tree object

=head1 VERSION

This document describes version 0.030 of Tree::ObjectXS::Hash (from Perl distribution Tree-ObjectXS), released on 2021-10-07.

=head1 SYNOPSIS

 use Tree::ObjectXS::Hash;
 my $tree = Tree::ObjectXS::Hash->new(attr1 => ..., attr2 => ...);

=head1 DESCRIPTION

This is just like L<Tree::Object::Hash> except that it: 1) uses
L<Class::XSAccessor::Array> to generate C<new>, C<parent>, C<children>.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-ObjectXS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-ObjectXS>.

=head1 SEE ALSO

L<Tree::Object::Hash>

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
