package Tree::Simple::View;

use strict;
use warnings;

our $VERSION = '0.19';

use Scalar::Util qw(blessed);

use Tree::Simple::View::Exceptions;

sub new {
    my ($_class, $tree, %configuration) = @_;
    my $class = ref($_class) || $_class;
    ($class ne 'Tree::Simple::View')
        || throw Tree::Simple::View::AbstractClass "Tree::Simple::View is an abstract class, try Tree::Simple::View::HTML or Tree::Simple::View::DHTML instead";
    my $tree_view = bless{
        tree                  => undef,
        config                => {},
        include_trunk         => undef,
        ppath_comparison_func => undef
    } => $class;
    $tree_view->_init($tree, %configuration);
    return $tree_view;
}

sub _init {
    my ($self, $tree, %config) = @_;
    (blessed($tree) && $tree->isa("Tree::Simple"))
        || throw Tree::Simple::View::InsufficientArguments "tree argument must be a Tree::Simple object";
    $self->{tree}					= $tree;
    $self->{config}					= \%config if %config;
    $self->{include_trunk}			= 0;
    $self->{path_comparison_func}	= undef;
}

sub getTree   { (shift)->{tree}   }
sub getConfig { (shift)->{config} }

sub includeTrunk {
    my ($self, $boolean) = @_;
    $self->{include_trunk} = ($boolean ? 1 : 0) if defined $boolean;
    return $self->{include_trunk};
}

sub setPathComparisonFunction {
    my ($self, $code) = @_;
    (defined($code) && ref($code) eq "CODE")
        || throw Tree::Simple::View::InsufficientArguments "Path comparison must be a function";
    $self->{path_comparison_func} = $code;
}

sub expandPath {
    my ($self, @path) = @_;
    return $self->expandPathComplex($self->{tree}, $self->{config}, @path) if (keys %{$self->{config}});
    return $self->expandPathSimple($self->{tree}, @path);
}

# override these method
sub expandPathSimple  { throw Tree::Simple::View::AbstractMethod "Method Not Implemented" }
sub expandPathComplex { throw Tree::Simple::View::AbstractMethod "Method Not Implemented" }

sub expandAll {
	my ($self) = @_;
	return $self->expandAllComplex($self->{config}) if (keys %{$self->{config}});
	return $self->expandAllSimple();
}

# override these method
sub expandAllSimple  { throw Tree::Simple::View::AbstractMethod "Method Not Implemented" }
sub expandAllComplex { throw Tree::Simple::View::AbstractMethod "Method Not Implemented" }

## private methods

sub _compareNodeToPath {
    my ($self, $current_path, $current_tree) = @_;
    # default to normal node-path comparison ...
    return $current_path eq $current_tree->getNodeValue()
        unless defined $self->{path_comparison_func};
    # unless we have a path_comparison_func in place
    # in which case we use that
    return $self->{path_comparison_func}->($current_path, $current_tree);
}

1;

__END__

=pod

=head1 NAME

Tree::Simple::View - A set of classes for viewing Tree::Simple hierarchies

=head1 SYNOPSIS

  # create a custom Tree View class
  package MyCustomTreeView;

  use strict;
  use warnings;

  # inherit from this class
  our @ISA = qw(Tree::Simple::View);

  # define (at a minimum) these methods
  sub expandPathSimple { ... }
  sub expandPathComplex { ... }

  sub expandAllSimple { ... }
  sub expandAllComplex { ... }

  1;

=head1 DESCRIPTION

This serves as an abstract base class to the Tree::Simple::View::* classes. There are
two implementing classes included here; Tree::Simple::View::HTML and Tree::Simple::View::DHTML.
Other Tree::Simple::View::* classes are also being planned, see the L<TO DO> section
for more information.

These modules should be considered stable and ready for production use. We have been using
this module in production on a number of sites for several years now without issue.

=head1 METHODS

=over 4

=item B<new ($tree, %configuration)>

Accepts a C<$tree> argument of a Tree::Simple object (or one derived from Tree::Simple),
if C<$tree> is not a Tree::Simple object, and exception is thrown. This C<$tree> object
does not need to be a ROOT, you can start at any level of the tree you desire. The options
in the C<%config> argument are determined by the implementing subclass, and you should
refer to that documentation for details.

=item B<getTree>

A basic accessor to reach the underlying tree object.

=item B<getConfig>

A basic accessor to reach the underlying configuration hash.

=item B<includeTrunk ($boolean)>

This controls the getting and setting (through the optional C<$boolean> argument) of the
option to include the tree's trunk in the output. Many times, the trunk is not actually
part of the tree, but simply a root from which all the branches spring. However, on
occasion, it might be necessary to view a sub-tree, in which case, the trunk is likely
intended to be part of the output. This option defaults to off.

=item B<setPathComparisonFunction ($CODE)>

This takes a C<$CODE> reference, which can be used to add custom path comparison features
to Tree::Simple::View. The function will get two arguments, the first is the C<$current_path>,
the second is the C<$current_tree>. When using C<expandPath>, it may sometimes be
nessecary to be able to control the comparison of the path values. For instance, your
node may be an object and need a specific method called to match the path against.

=item B<expandPath (@path)>

This method will return a string which will represent your tree expanded along the
given C<@path>. This is best shown visually. Given this tree:

  Tree-Simple-View
      lib
          Tree
              Simple
                  View.pm
                  View
                      HTML.pm
                      DHTML.pm
      Makefile.PL
      MANIFEST
      README
      Changes
      t
          10_Tree_Simple_View_test.t
          20_Tree_Simple_View_HTML_test.t
          30_Tree_Simple_View_DHTML_test.t

And given this path:

  Tree-Simple-View, lib, Tree, Simple

Your display would like something like this:

  Tree-Simple-View
      lib
          Tree
              Simple
                  View.pm
                  View
      Makefile.PL
      MANIFEST
      README
      Changes
      t

As you can see, the given path has been expanded, but no other sub-trees are shown. The
details of this are subject to the implementating subclass, and their documentation should
be consulted.

It should be noted that this method actually calls either the C<expandPathSimple> or
C<expandPathComplex> method depending upon the C<%config> argument in the constructor.

=item B<expandPathSimple ($tree, @path)>

Within this base package, this is an abstract method, it will throw an exception if
called.

If no C<%config> argument is given in the constructor, then this method is called by
C<expandPath>. This method is optimized since it does not need to process any configuration,
but just as the name implies, it's output is simple.

This method can also be used for another purpose, which is to bypass a previously
specified configuration and use the base "simple" configuration instead.

=item B<expandPathComplex ($tree, $config, @path)>

Within this base package, this is an abstract method, it will throw an exception
if called.

If a C<%config> argument is given in the constructor, then this method is called
by C<expandPath>. This method has been optimized to be used with configurations, and
will actually custom compile code (using C<eval>) to speed up the generation of the
output.

This method can also be used for another purpose, which is to bypass a previously
specified configuration and use the configuration specified (as a HASH reference)
in the C<$config> parameter.

=item B<expandAll>

This method will return a string of HTML which will represent your tree completely
expanded. The details of this are subject to the implementating subclass, and their
documentation should be consulted.

It should be noted that this method actually calls either the C<expandAllSimple> or
C<expandAllComplex> method depending upon the C<%config> argument in the constructor.

=item B<expandAllSimple>

Within this base package, this is an abstract method, it will throw an exception
if called.

If no C<%config> argument is given in the constructor, then this method is called
by C<expandAll>. This method too is optimized since it does not need to process any
configuration.

This method as well can also be used to bypass a previously specified configuration
and use the base "simple" configuration instead.

=item B<expandAllComplex ($config)>

Within this base package, this is an abstract method, it will throw an exception
if called.

If a C<%config> argument is given in the constructor, then this method is called by
C<expandAll>. This method too has been optimized to be used with configurations, and
will also custom compile code (using C<eval>) to speed up the generation of the output.

Just as with C<expandPathComplex>, this method can be to bypass a previously specified
configuration and use the configuration specified (as a HASH reference) in the
C<$config> parameter.

=back

=head1 DEMO

To view a demo of the Tree::Simple::View::DHTML functionality, look in the C<examples/>
directory.

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure
to fix it.

=head1 SEE ALSO

This is just an abstract base class, I suggest you read the documentation in the implementing
subclasses:

=over 4

=item B<Tree::Simple::View::HTML>

=item B<Tree::Simple::View::DHTML>

=back

There are a few modules out there that I have seen which do similar things to these modules.
I have attempted to describe them here, but not being a user of these modules myself,
I can not do them justice. If you think I have mis-represented or just under-represented
these modules, please let me know. Also, if I have not included a module which should be here,
let me know and I will add it.

=over 4

=item L<Data::TreeDumper>

This module is an alternative to Data::Dumper for dumping out any type of data structures.
As the author points out, the output of Data::Dumper when dealing with tree structures can
be difficult to read at best. This module solves that problem by dumping a much more readable
and understandable output specially for tree structures. Data::TreeDumper has many options
for output, including custom filters and coloring. I have been working with this module's author
and we have been sharing code. Data::TreeDumper can output L<Tree::Simple> objects
(L<http://search.cpan.org/~nkh/Data-TreeDumper-0.15/TreeDumper.pm#Structure_replacement>).
This gives Tree::Simple the ability to utilize the ASCII/ANSI output  styles of Data::TreeDumper.
Nadim has used some of the code from  Tree::Simple::View to add DHTML output to Data::TreeDumper.
The DHTML output can be without tree-lines as for Tree::Simple::View or with tree-lines as with
Data::TreeDumper.

=item L<Data::RenderAsTree>

Abstract: Render any data structure as an object of type Tree::DAG_Node.

Similar to L<Data::TreeDumper>

=item L<HTML::PopupTreeSelect>

This module implements a DHTML "pop-up" dialog which contains an expand-collapse tree, which
can be used for selecting an item from a hierarchy. It looks to me to be very configurable
and have all its bases covered, right down to handling some of the uglies of
cross-browser/cross-platform DHTML. However it is really for a very specific purpose, and
not for general tree display like this module.

=item L<HTML::TreeStructured>

This module actually seems to do something very similar to these modules, but to be honest,
the documentation is very, very sparse, and so I am not really sure how to go about using it.
From a quick read of the code it seems to use HTML::Template as its base, but after that I
am not sure.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Thanks to Neyuki for the idea of the C<setPathComparisonFunction> method.

=item Thanks to Simon Wilcox for the patch and test for XHTML support for Tree::Simple::View::HTML.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

Ron Savage E<lt>ron@savage.net.auE<gt> is co-maint as of V 0.19.

=head1 REPOSITORY

L<https://github.com/ronsavage/Tree-Simple-View>.

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

