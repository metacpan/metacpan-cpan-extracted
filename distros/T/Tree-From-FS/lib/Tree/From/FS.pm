package Tree::From::FS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-06'; # DATE
our $DIST = 'Tree-From-FS'; # DIST
our $VERSION = '0.000.1'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(create_tree_from_dir);

sub create_tree_from_dir {
    die "Not yet implemented";
}

1;
# ABSTRACT: Create a tree object from directory structure on the filesystem

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::From::FS - Create a tree object from directory structure on the filesystem

=head1 VERSION

This document describes version 0.000.1 of Tree::From::FS (from Perl distribution Tree-From-FS), released on 2021-05-06.

=head1 SYNOPSIS

=head1 DESCRIPTION

B<PLACEHOLDER. NOT YET IMPLEMENTED.>

=head1 FUNCTIONS

=head2 create_tree_from_dir($path) => obj

This module provides a convenience function to build a tree of objects that
mirrors a directory structure on the filesystem. Each node will represent a file
or a subdirectory.

The class can be any class that provides C<parent> and C<children> methods. See
L<Role::TinyCommons::Tree::Node> for more details on the requirement.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-From-FS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-From-FS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Tree-From-FS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Tree>

Other ways to create tree: L<Tree::From::Struct>, L<Tree::From::ObjArray>,
L<Tree::From::Text>, L<Tree::From::TextLines>, L<Tree::Create::Callback>,
L<Tree::Create::Size>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
