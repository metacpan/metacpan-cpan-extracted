package Tree::Object::Array;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'Tree-Object'; # DIST
our $VERSION = '0.080'; # VERSION

sub import {
    my ($class0, @attrs) = @_;

    my $caller = caller();

    my $code_str = "package $caller;\n";

    $code_str .= "use Class::Accessor::Array {\n";
    $code_str .= "    accessors => {\n";
    my $idx = 0;
    for (@attrs, "parent", "children") {
        $code_str .= "        '$_' => $idx,\n";
        $idx++;
    }
    $code_str .= "    },\n";
    $code_str .= "};\n";

    $code_str .= "use Role::Tiny::With;\n";
    $code_str .= "with 'Role::TinyCommons::Tree::NodeMethods';\n";

    #say $code_str;

    eval $code_str; ## no critic: BuiltinFunctions::ProhibitStringyEval
    die if $@;
}

1;
# ABSTRACT: An array-based tree object

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::Object::Array - An array-based tree object

=head1 VERSION

This document describes version 0.080 of Tree::Object::Array (from Perl distribution Tree-Object), released on 2021-10-07.

=head1 SYNOPSIS

In F<lib/My/ArrayTree.pm>:

 package My::ArrayTree;
 use Tree::Object::Array qw(attr1 attr2 attr3);
 1;

=head1 DESCRIPTION

This module lets you create an array-backed (instead of hash-backed) tree
object. Instead of subclassing C<Tree::Object::Hash>, you C<use> it in your
class and listing all the attributes you will need. It uses
L<Class::Accessor::Array> to store data:

 [$attr1, $attr2, ..., $parent, \@children]

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-Object>.

=head1 SEE ALSO

L<Tree::Object::Array::Glob>, a variant which stores the children nodes directly
as the last elements of the array to avoid creating an extra subarray.

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
