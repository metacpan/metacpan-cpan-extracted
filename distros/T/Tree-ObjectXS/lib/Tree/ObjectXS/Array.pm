package Tree::ObjectXS::Array;

our $DATE = '2016-03-29'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

sub import {
    my ($class0, @attrs) = @_;

    my $caller = caller();

    my $code_str = "package $caller;\n";
    $code_str .= "use Class::XSAccessor::Array {\n";
    $code_str .= "    constructor => 'new',\n";
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

    eval $code_str;
    die if $@;
}

1;
# ABSTRACT: An array-based tree object

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::ObjectXS::Array - An array-based tree object

=head1 VERSION

This document describes version 0.02 of Tree::ObjectXS::Array (from Perl distribution Tree-ObjectXS), released on 2016-03-29.

=head1 SYNOPSIS

In F<lib/My/ArrayTree.pm>:

 package My::ArrayTree;
 use Tree::ObjectXS::Array qw(attr1 attr2 attr3);
 1;

=head1 DESCRIPTION

This is just like L<Tree::Object::Array> except: 1) it uses
L<Class::XSAccessor::Array> to generate the accessor methods and the
constructor.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-ObjectXS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-ObjectXS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-ObjectXS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
