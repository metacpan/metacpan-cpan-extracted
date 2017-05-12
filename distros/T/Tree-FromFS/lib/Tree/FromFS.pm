package Tree::FromFS;

our $DATE = '2016-03-29'; # DATE
our $VERSION = '0.00'; # VERSION

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

Tree::FromFS - Create a tree object from directory structure on the filesystem

=head1 VERSION

This document describes version 0.00 of Tree::FromFS (from Perl distribution Tree-FromFS), released on 2016-03-29.

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

Please visit the project's homepage at L<https://metacpan.org/release/Tree-FromFS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-FromFS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-FromFS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Tree>

Other ways to create tree: L<Tree::FromStruct>, L<Tree::FromText>,
L<Tree::FromTextLines>, L<Tree::Create::Callback>, L<Tree::Create::Size>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
