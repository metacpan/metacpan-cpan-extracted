package Tree::To::TextLines;

our $DATE = '2021-05-06'; # DATE
our $VERSION = '0.061'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;
use Scalar::Util qw(reftype looks_like_number);

use Exporter qw(import);
our @EXPORT_OK = qw(render_tree_as_text);

sub _render_attr {
    my ($node, $attr) = @_;

    my $val;
    if ($attr =~ /\A\w+\z/ && $node->can($attr)) {
        $val = $node->$attr;
    } elsif (reftype($node) eq 'HASH' && exists $node->{$attr}) {
        $val = $node->{$attr};
    } else {
        $val = undef;
    }

    if (!defined($val) || ref($val) || !looks_like_number($val)) {
        $val = dmp($val);
    }

    $val;
}

sub _render_node {
    my ($opts, $node, $seniority, $is_last_childs) = @_;

    my $level = @$is_last_childs;

    my $res = "";

    # draw indent
    for my $l (1..$level) {
        if ($opts->{show_guideline}) {
            if ($is_last_childs->[$l-1]) {
                $res .= ($l == $level ? "\\" : " ");
            } else {
                $res .= ($l == $level ? "|" : "|");
            }
            $res .= ($l == $level ? "-" : " ") x $opts->{indent};
            $res .= " ";
        } else {
            $res .= " " x $opts->{indent};
        }
    }

    my $node_res;
    if ($opts->{on_show_node}) {
        $node_res = $opts->{on_show_node}->(
            $node, $level, $seniority,
            @$is_last_childs == 0 ? 1 : $is_last_childs->[-1],
            $opts);
    } else {
        $node_res = "";

        if ($opts->{show_class_name}) {
            my $class = ref($node);
            $node_res .= "($class) ";
        }

        my $id;
        if (defined (my $attr = $opts->{id_attribute})) {
            $id = ($opts->{show_attribute_name} ? "$attr:" : "") .
                _render_attr($node, $attr);
        } else {
            $id = "$node";
            $id =~ s/\R.*//s;
        }
        $node_res .= $id;

        if ($opts->{extra_attributes}) {
            for my $attr (@{ $opts->{extra_attributes} }) {
                my $v = ($opts->{show_attribute_name} ? "$attr:" : "").
                    _render_attr($node, $attr);
                $node_res .= " $v";
            }
        }
    }
    $res .= "$node_res\n";

    my $get_children_method = $opts->{get_children_method} // 'children';

    my @children;
    eval { @children = $node->$get_children_method };
    unless ($@) {
        @children = () unless defined($children[0]);
        @children = @{$children[0]} if @children==1 && ref($children[0]) eq 'ARRAY';
    }

    my @children_res;
    for my $i (0..$#children) {
        my $is_last_child = $i == $#children ? 1:0;
        push @children_res,
            _render_node(
                $opts, $children[$i], $i, [@$is_last_childs, $is_last_child]);
    }

    ($res, @children_res);
}

sub render_tree_as_text {
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
        $opts = {%$opts}; # shallow clone
    } else {
        $opts = {};
    }

    $opts->{indent} //= 2;
    $opts->{show_guideline} //= 0;
    $opts->{on_show_node} //= undef;

    $opts->{id_attribute} //= undef;
    $opts->{show_attribute_name} //= 1;
    $opts->{show_class_name} //= 0;
    $opts->{extra_attributes} //= undef;

    my $tree = shift;

    join("", _render_node($opts, $tree, 0, []));
}

1;
# ABSTRACT: Render a tree object as indented text lines

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::To::TextLines - Render a tree object as indented text lines

=head1 VERSION

This document describes version 0.061 of Tree::To::TextLines (from Perl distribution Tree-To-Text), released on 2021-05-06.

=head1 SYNOPSIS

 use Tree::To::TextLines qw(render_tree_as_text);

 my $tree = ...; # you can build a tree e.g. using Tree::From::Struct, Tree::From::ObjArray, or Tree::From::TextLines

Using default option:

 print render_tree_as_text($tree);

Sample output:

 Tree::Example::HashNode=HASH(0xca80e0)
   Tree::Example::HashNode::Sub1=HASH(0xbd8c10)
     Tree::Example::HashNode::Sub2=HASH(0xd8b518)
       Tree::Example::HashNode::Sub1=HASH(0xd8b710)
         Tree::Example::HashNode::Sub2=HASH(0xd8bc50)
       Tree::Example::HashNode::Sub1=HASH(0xd8b788)
       Tree::Example::HashNode::Sub1=HASH(0xd8b830)
       Tree::Example::HashNode::Sub1=HASH(0xd8b8d8)
   Tree::Example::HashNode::Sub1=HASH(0xd8b3b0)
     Tree::Example::HashNode::Sub2=HASH(0xd8b620)
       Tree::Example::HashNode::Sub1=HASH(0xd8b980)
         Tree::Example::HashNode::Sub2=HASH(0xd8bce0)
       Tree::Example::HashNode::Sub1=HASH(0xd8ba58)
       Tree::Example::HashNode::Sub1=HASH(0xd8bb00)
       Tree::Example::HashNode::Sub1=HASH(0xd8bba8)
   Tree::Example::HashNode::Sub1=HASH(0xd8b470)

Customize options:

 print render_tree_as_text({
     #indent               => 2,
     show_guideline        => 1,        # default: 0
     id_attribute          => 'id',     # default: undef
     #show_attribute_name  => 1,
     #show_class_name      => 0,
     #extra_attributes     => [..., ...], # default: undef
 }, $tree);

Sample output:

 id:1
 |-- id:2
 |   \-- id:5
 |       |-- id:7
 |       |   \-- id:15
 |       |-- id:8
 |       |-- id:9
 |       \-- id:10
 |-- id:3
 |   \-- id:6
 |       |-- id:11
 |       |   \-- id:16
 |       |-- id:12
 |       |-- id:13
 |       \-- id:14
 \-- id:4

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 render_tree_as_text([ \%opts, ] $tree) => str

This function renders a tree object C<$tree> as lines of text, each line showing
a node and indented differently according to the node's position in the tree. A
child node will be indented more deeply than its parent node.

Tree object of any kind of class is accepted as long as the class responds to
C<children> and the method returns a list or arrayref of children nodes. The
name of the children method C<children> can be customized using
C<get_children_method> option.

This function is the complement for C<build_tree_from_text_lines> function in
L<Tree::From::TextLines>.

When C<on_show_node> option is specified, that routine will be called with
C<($node, $level, $seniority, $is_last_child, $opts)> and the return value will
be used to display each node. Otherwise, the default behavior to show each node
is as follow:

By default a node will be shown using:

 "$node"

that is, class name followed by its stringified value, which by default when not
overloaded by the object will be something like:

 Foo=HASH(0x1472160)

If C<id_attribute> is specified, then instead the node will be shown using:

 $node->id

where C<id> is the name of the ID attribute.

Rule to render value of attribute: If attribute name does not match C</\A\w+\z/>
or a node does not respond to the getter method of that name, and the object is
hash-based, then hash key of that name will be used instead. If said hash key
does not exist also, C<undef> will be used. When displaying the value of an
attribute, Data::Dmp will be used for non-number strings and references.

After that, if C<extra_attributes> is set (e.g. to C<["foo", "bar"]>), will show
the value of the attributes:

 $node->id . " " . ref($node) . " " . $node->foo . " " . $node->bar

The same rule for ID attribute will be used to render the value of these
attributes.

If C<show_class_name> is set to true, will prepend with class name in
parentheses, e.g.:

 ($class) ...

Available options:

=over

=item * get_children_method => str (default: children)

Example:

 get_children_method => "get_children"

By default, C<children> is the method that will be used on node objects to
retrieve children nodes. But you can customize that using this option. Note that
the method must return either a list or arrayref of nodes.

=item * indent => int (default: 2)

Number of spaces for each indent level.

=item * show_guideline => bool (default: 0)

If set to false, then the tree will just a set of indented lines, e.g.:

 id:1
   id:2
   id:3
     id:4
   id:5

If set to true, guidelines will be shown, e.g.:

 id:1
 |-- id:2
 |-- id:3
 |   \-- id:4
 \-- id:5

=item * id_attribute => str (default: undef)

Name of ID attribute. If ID attribute is not specified, each node will be shown
as stringified object (only first line used), e.g.:

 Tree::Object::Hash=HASH(0x209a160)
   Tree::Object::Hash=HASH(0xfc9160)
   Tree::Object::Hash=HASH(0xac7160)

If ID attribute is used, the value of this attribute will be used instead, e.g.:

 id:node0
   id:node1
   id:node2

=item * show_class_name => bool (default: 0)

Whether to show class name before showing node, e.g. when false:

 id:1
   id:2
   id:3
     id:4
   id:5

When true:

 (Tree::Object) id:1
   (Tree::Object) id:2
   (Tree::Object) id:3
     (Tree::Object::Subclass) id:4
   (Tree::Object) id:5

=item * extra_attributes => array of str (default: undef)

When specified, will show the extra attributes after the ID attribute and class
name, e.g. when set to C<["foo","bar"]>:

 id:1 foo:a bar:b
   id:2 foo:c bar:b
   id:3 foo: bar:d
     id:4 foo:a2 bar:b2
   id:5 foo:a bar:b

=item * show_attribute_name => bool (default: 1)

When set to true, each time an attribute is shown its name will be printed
first, e.g.:

 id:1 foo:a bar:b
   id:2 foo:c bar:b
   id:3 foo: bar:d
     id:4 foo:a2 bar:b2
   id:5 foo:a bar:b

When set to false:

 1 a b
   2 c b
   3  d
     4 a2 b2
   5 a b

=item * on_show_node => code

Can be used to completely customize how to display a node. It will be called
with these arguments:

 ($node, $level, $seniority, $is_last_child, $opts)

where C<$level> is 0 for the root node, 1 for the root's children, and so on.
C<$seniority> is 0 for the first child, 1 for the second, and so on.
C<$is_last_child> will be set to true if node is the last child. The code should
return a string that will be used to display a node.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-To-Text>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-To-Text>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Tree-To-Text/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Tree::From::Text>, L<Tree::From::TextLines>

L<Tree::From::Struct>, L<Tree::From::ObjArray>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
