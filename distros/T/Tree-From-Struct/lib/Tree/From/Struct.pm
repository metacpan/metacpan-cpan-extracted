package Tree::From::Struct;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-06'; # DATE
our $DIST = 'Tree-From-Struct'; # DIST
our $VERSION = '0.041'; # VERSION

require Code::Includable::Tree::FromStruct;

use Exporter qw(import);
our @EXPORT_OK = qw(build_tree_from_struct);

sub build_tree_from_struct {
    my $struct = shift;

    my $class = $struct->{_class} or die "Please specify _class in struct";
    Code::Includable::Tree::FromStruct::new_from_struct($class, $struct);
}

1;
# ABSTRACT: Build a tree object from hash structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::From::Struct - Build a tree object from hash structure

=head1 VERSION

This document describes version 0.041 of Tree::From::Struct (from Perl distribution Tree-From-Struct), released on 2021-05-06.

=head1 SYNOPSIS

In your tree node class F<My/Person.pm>:

 package My::Person;

 sub new {
     my $class = shift;
     my %args = @_;
     bless \%args, $class;
 }

 sub parent {
     my $self = shift;
     $self->{_parent} = $_[0] if $@;
     $self->{_parent};
 }

 sub children {
     my $self = shift;
     $self->{_children} = $_[0] if $@;
     $self->{_children};
 }

In your code to build a tree:

 use Tree::From::Struct qw(build_tree_from_struct);

 # require all the used classes
 use My::Person;
 use My::MarriedPerson;
 use My::KidPerson;

 my $family_tree = build_tree_from_struct({
     _class => 'My::Person', name => 'Andi', age => 60, _children => [
         {name => 'Budi', age => 30},
         {_class => 'My::MarriedPerson', name => 'Cinta', _children => [
              {class => 'My::KidPerson', name => 'Deni'},
              {class => 'My::KidPerson', name => 'Eno'},
          ]},
     ]});

This tree is visualized as follows:

 Andi
   ├─Budi
   └─Cinta
       ├─Deni
       └─Eno

=head1 DESCRIPTION

Building a tree manually can be tedious: you have to connect the parent and
the children nodes together:

 my $root = My::TreeNode->new(...);
 my $child1 = My::TreeNode->new(...);
 my $child2 = My::TreeNode->new(...);

 $root->children([$child1, $child2]);
 $child1->parent($root);
 $child2->parent($root);

 my $grandchild1 = My::TreeNode->new(...);
 ...

This module provides a convenience function to build a tree of objects in a
single command. It connects the parent and children nodes for you.

The class can be any class that provides C<parent> and C<children> methods. See
L<Role::TinyCommons::Tree::Node> for more details.

=head1 FUNCTIONS

=head2 build_tree_from_struct($struct) => obj

This is basically L<Role::TinyCommons::Tree::FromStruct>'s C<new_from_struct>
presented as a function. See the role's documentation for more details on what
you can put in C<$struct>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-From-Struct>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-From-Struct>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Tree-From-Struct/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Tree::FromStruct> if you want to use this functionality via
consuming a role.

Another way to create tree from a nested array of objects:
L<Tree::From::ObjArray>.

Other ways to create tree: L<Tree::From::Text>, L<Tree::From::TextLines>,
L<Tree::Create::Callback>, L<Tree::Create::Size>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
