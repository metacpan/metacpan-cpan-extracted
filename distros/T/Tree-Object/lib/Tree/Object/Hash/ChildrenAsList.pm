package Tree::Object::Hash::ChildrenAsList;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'Tree-Object'; # DIST
our $VERSION = '0.080'; # VERSION

with 'Role::TinyCommons::Tree::NodeMethods';

sub new {
    my $class = shift;
    my %attrs = @_;
    $attrs{_parent} //= undef;
    $attrs{_children} //= [];
    bless \%attrs, $class;
}

sub parent {
    my $self = shift;
    $self->{_parent} = $_[0] if @_;
    $self->{_parent};
}

sub children {
    my $self = shift;

    $self->{_children} = $_[0] if @_;
    @{ $self->{_children} };
}

1;
# ABSTRACT: A hash-based tree object, children() returns list

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::Object::Hash::ChildrenAsList - A hash-based tree object, children() returns list

=head1 VERSION

This document describes version 0.080 of Tree::Object::Hash::ChildrenAsList (from Perl distribution Tree-Object), released on 2021-10-07.

=head1 SYNOPSIS

 use Tree::Object::Hash::ChildrenAsList;
 my $tree = Tree::Object::Hash::ChildrenAsList->new(attr1 => ..., attr2 => ...);

=head1 DESCRIPTION

This class is exactly like L<Tree::Object::Hash> but its C<children()> returns a
list instead of arrayref. It is used for testing purposes only.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-Object>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-Object>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
