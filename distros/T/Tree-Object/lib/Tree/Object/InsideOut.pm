package Tree::Object::InsideOut;

our $DATE = '2016-04-14'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;

use Class::InsideOut qw(public register id);

public parent   => my %parent;
public children => my %children;

use Role::Tiny::With;

with 'Role::TinyCommons::Tree::NodeMethods';

sub new {
    my $self = register(shift);
    $children{ id $self } //= [];
    $self;
}

1;
# ABSTRACT: A tree object using Class::InsideOut

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::Object::InsideOut - A tree object using Class::InsideOut

=head1 VERSION

This document describes version 0.07 of Tree::Object::InsideOut (from Perl distribution Tree-Object), released on 2016-04-14.

=head1 SYNOPSIS

 use Tree::Object::InsideOut;
 my $tree = Tree::Object::InsideOut->new();

=head1 DESCRIPTION

This module lets you create a L<Class::InsideOut>-based (instead of regular
hash-backed) tree object. To subclass this class, please see the documentation
of Class::InsideOut.

=for Pod::Coverage ^(new)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-Object>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
