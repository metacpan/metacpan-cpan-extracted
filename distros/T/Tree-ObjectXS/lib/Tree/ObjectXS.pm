package Tree::ObjectXS;

our $DATE = '2016-03-29'; # DATE
our $VERSION = '0.02'; # VERSION

1;
# ABSTRACT: Generic tree objects (with XS accessors, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::ObjectXS - Generic tree objects (with XS accessors, etc)

=head1 VERSION

This document describes version 0.02 of Tree::ObjectXS (from Perl distribution Tree-ObjectXS), released on 2016-03-29.

=head1 DESCRIPTION

This distribution provides several implementations of tree classes (and class
generators) which you can use directly or as a base class. All of them consume
the roles from L<Role::TinyCommons::Tree> distribution.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-ObjectXS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Tree::Object>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
