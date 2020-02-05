package Tree::To::FS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-04'; # DATE
our $DIST = 'Tree-To-FS'; # DIST
our $VERSION = '0.000'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(create_dir_from_tree);

sub create_dir_from_tree {
    die "Not yet implemented";
}

1;
# ABSTRACT: Create a directory structure using tree object

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::To::FS - Create a directory structure using tree object

=head1 VERSION

This document describes version 0.000 of Tree::To::FS (from Perl distribution Tree-To-FS), released on 2020-02-04.

=head1 SYNOPSIS

=head1 DESCRIPTION

B<PLACEHOLDER. NOT YET IMPLEMENTED.>

=head1 FUNCTIONS

=head2 create_dir_from_tree($tree, $target_dir) => undef

This module is a counterpart of C<create_tree_from_dir()> function in
L<Tree::From::FS>. It creates a directory structure that mirrors the structure
of the tree object. Each node will become a file or a subdirectory.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-To-FS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-ToFS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-To-FS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Tree::From::FS>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
