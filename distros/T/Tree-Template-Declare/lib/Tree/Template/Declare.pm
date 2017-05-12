package Tree::Template::Declare;
{
  $Tree::Template::Declare::DIST = 'Tree-Template-Declare';
}
$Tree::Template::Declare::VERSION = '0.7';
use strict;
use warnings;
use Sub::Exporter;
use Devel::Caller 'caller_args';
use Carp;
use 5.006;

{
my $exporter=Sub::Exporter::build_exporter({
    groups => {
        default => \&_build_group,
    },
});

sub import {
    my ($pack,@rest)=@_;

    if (@rest) {
        @_=($pack,-default => {@rest});
    }
    goto $exporter;
}
}

our @nodes_stack;

sub _build_group {
    my ($class,$name,$args,$coll)=@_;

    my $builder=$args->{builder};

    if (! ref $builder) {
        my $builder_pkg=$builder;
        if ($builder_pkg=~m{\A [+](\w+) \z}smx) {
            $builder_pkg="Tree::Template::Declare::$1";
        }
        eval "require $builder_pkg" ## no critic (ProhibitStringyEval)
            or croak "Can't load $builder_pkg: $@"; ## no critic (ProhibitPunctuationVars)

        if ($builder_pkg->can('new')) {
            $builder=$builder_pkg->new();
        }
        else {
            $builder=$builder_pkg;
        }
    }

    my $normal_exports= {
        tree => sub(&) {
            my $tree=$builder->new_tree();

            unshift @nodes_stack,$tree;
            $_[0]->(caller_args(1));
            shift @nodes_stack;

            return $builder->finalize_tree($tree);
        },
        node => sub (&) {
            my $node=$builder->new_node();

            unshift @nodes_stack, $node;
            $_[0]->(caller_args(1));
            shift @nodes_stack;

            my $scalar_context=defined wantarray && !wantarray;
            if (@nodes_stack && !$scalar_context) {
                $builder->add_child_node($nodes_stack[0],$node);
            }
            return $node;
        },
        attach_nodes => sub {
            if (@nodes_stack) {
                for my $newnode (@_) {
                    $builder->add_child_node($nodes_stack[0],
                                             $newnode);
                }
            }
        },
        name => sub ($) {
            $builder->set_node_name($nodes_stack[0],$_[0]);
            return;
        },
        attribs => sub {
            my %attrs=@_;
            $builder->set_node_attributes($nodes_stack[0],\%attrs);
            return;
        },
        detached => sub($) { return scalar $_[0] },
    };
    if ($builder->can('_munge_exports')) {
        return $builder->_munge_exports($normal_exports,\@nodes_stack);
    }
    else {
        return $normal_exports;
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Tree::Template::Declare - easily build tree structures

=head1 VERSION

version 0.7

=head1 SYNOPSIS

 use Tree::Template::Declare builder => '+DAG_Node';

 my $tree=tree {
     node {
         name 'root';
         attribs name => 'none';
         node {
             name 'first';
             attribs name => 'number_1';
             attribs other => 'some';
         };
         node {
             name 'second';
         };
     };
 };

=head1 FUNCTIONS

For details on the implementation of these functions, see the
L</BUILDER> section, and the documentation of your chosen builder.

=head2 C<tree>

This function takes a code ref or a block, inside which calls to
C<node> should be made, and returns a properly constructed tree
containing those nodes.

Uses the builder's C<new_tree> and C<finalize_tree>.

=head2 C<node>

This function takes a code ref or a block, inside which calls to
C<name>, C<attribs>, and C<node> should be made, and returns the node.

If I<not> called in scalar context, it also adds the node to the
"calling" node or tree.

Uses the builder's C<new_node> and C<add_child_node>.

=head2 C<detached>

Alias for C<scalar>, so that you can say C<return detached node ...>
without having to worry about the calling context.

=head2 C<attach_nodes>

This function takes a list of nodes, and adds them (in order) to the
"calling" node or tree. You should only use this with nodes you
obtained by calling C<node> in scalar context.

Uses the builder's C<add_child_node>.

=head2 C<name>

This function takes a scalar, and sets the name of the current node to
the value of that scalar.

Uses the builder's C<set_node_name>.

=head2 C<attribs>

This function takes a hash (not a hash ref), and sets the attributes
of the current node.

Uses the builder's C<set_node_attributes>.

=head1 BUILDER

To actually create nodes and trees, this module uses helper classes
called "builders". You must always specify a builder package, class or
object with the C<builder> option in the C<use> line.

If the builder is an object, the methods discussed below will be
called on it; if it's a class (i.e. a package that has a C<new>
function), they will be called on an instance created by calling
C<new> without parameters; otherwise they will be called as class
methods.

The builder must implement these methods:

=over

=item C<new_tree>

 $tree = $current_node = $builder->new_tree();

returns a tree object; that object will be set as the current node
within the code passed to the C<tree> function

=item C<finalize_tree>

  return $builder->finalize_tree($tree);

this function will be passed the object returned by C<new_tree>, after
the code passed to C<tree> has been executed; the result of
C<finalize_tree> will be the result of C<tree>

=item C<new_node>

  $current_node=$builder->new_node();

returns a new, unattached node

=item C<set_node_name>

  $builder->set_node_name($current_node, $name);

sets the name of the node (e.g. for SGML-like trees, this is the "tag
name")

=item C<set_node_attributes>

  $builder->set_node_attributes($current_node, \%attribs);

sets attributes of the node; it should not remove previously-set attributes

=item C<add_child_node>

  $builder->add_child_node($parent_node, $child_node);

adds the second node at the end of the children list of the first node

=back

The builder can also implement an C<_munge_exports> method. If it
does, C<_munge_exports> will be called with:

=over 4

=item *

a hash ref consisting of the functions that C<Tree::Template::Declare>
wants to export,

=item *

an array ref, whose first element will be the current node whenever
the user calls an exported function

=back

C<_munge_exports> should return a hash ref with the functions that
will actually be exported.

See L<Sub::Exporter>, in particular the section on group builders, for
details. See L<Tree::Template::Declare::HTML_Element> and
L<Tree::Template::Declare::LibXML> for examples.

=head1 IMPORTING

This module uses L<Sub::Exporter>, although it munges the C<use> list
before passing it to L<Sub::Exporter>. A line like:

 use Tree::Template::Declare @something;

becomes a call to L<Sub::Exporter>'s export sub like:

 $export->('Tree::Template::Declare',-default => {@something});

See L<Sub::Exporter>'s documentation for things like renaming the
imports.

You can C<use> this module more than once, with different builders and
different names for the imports:

 use Tree::Template::Declare -prefix=> 'x', builder => '+LibXML';
 use Tree::Template::Declare -prefix=> 'd', builder => '+DAG_Node';

=head1 KNOWN ISSUES & BUGS

=over 4

=item *

C<_munge_exports> is ugly

=item *

the context-sensitivity of C<node> might not be the best way to DWIM
for the creation of detached nodes

=back

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: easily build tree structures

