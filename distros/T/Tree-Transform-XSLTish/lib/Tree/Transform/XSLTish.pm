package Tree::Transform::XSLTish;
use strict;
use warnings;
use Sub::Exporter;
use Params::Validate ':all';
use Tree::Transform::XSLTish::Utils;
use Tree::Transform::XSLTish::Transformer;
use Carp::Clan qw(^Tree::Transform::XSLTish);
use 5.006;

our $VERSION='0.3';

my @DEFAULT_EXPORTS=('tree_rule',
                     'default_rules',
                     'new_transformer' => {-as => 'new'},
                 );

Sub::Exporter::setup_exporter({
    exports => [qw(tree_rule default_rules new_transformer engine_class engine_factory)],
    groups => {
        default => \@DEFAULT_EXPORTS,
        engine => [@DEFAULT_EXPORTS, qw(engine_class engine_factory)],
    }
});

sub default_rules {
    my $store=Tree::Transform::XSLTish::Utils::_rules_store(scalar caller);

    push @{$store->{by_match}},
        {match=> '/',priority=>0,action=>sub { $_[0]->apply_rules } },
        {match=> '*',priority=>0,action=>sub { $_[0]->apply_rules } },
            ;
    return;
}

sub tree_rule {
    my (%args)=validate(@_, {
        match => { type => SCALAR, optional => 1 },
        action => { type => CODEREF },
        name => { type => SCALAR, optional => 1},
        priority => { type => SCALAR, default => 1 },
    });

    # TODO at least one of 'name' and 'match' must be specified
    # TODO default priority based on match

    my $store=Tree::Transform::XSLTish::Utils::_rules_store(scalar caller);

    if ($args{match}) {
        push @{$store->{by_match}},\%args;
    }
    if ($args{name}) {
        if (exists $store->{by_name}{$args{name}}) {
            carp "Duplicate rule named $args{name}, ignoring";
            return;
        }
        $store->{by_name}{$args{name}}=\%args;
    }

    return;
}

sub engine_class {
    my ($classname)=@_;

    Tree::Transform::XSLTish::Utils::_set_engine_factory(
        scalar caller,
        sub{$classname->new()},
    );

    return;
}

sub engine_factory(&) {
    my ($new_factory)=@_;

    Tree::Transform::XSLTish::Utils::_set_engine_factory(
        scalar caller,
        $new_factory,
    );

    return;
}

sub new_transformer {
    my $rules_package=shift;

    return Tree::Transform::XSLTish::Transformer->new(rules_package=>$rules_package,@_);
}

1;
__END__

=head1 NAME

Tree::Transform::XSLTish - transform tree data, like XSLT but in Perl

=head1 SYNOPSIS

  package MyTransform;
  use Tree::Transform::XSLTish;

  default_rules;

  tree_rule match => 'node[@id=5]', action => sub {
    return $_[0]->it->data();
  };

  package main;
  use My::Tree;

  my $tree= My::Tree->new();
  # build something inside the tree

  my ($node5_data)=MyTransform->new->transform($tree);

Transforming an HTML document:

 package HtmlTransform;
 use Tree::Transform::XSLTish;
 use strict;
 use warnings;

 engine_class 'XML::XPathEngine';

 default_rules;

 tree_rule match => 'img[@alt="pick"]', action => sub {
     return $_[0]->it->findvalue('@src');
 };

 package main;
 use HTML::TreeBuilder::XPath;

 my $tree=HTML::TreeBuilder::XPath->new();
 $tree->parse_file('mypage.html');

 my $trans=HtmlTransform->new();
 my ($image_srce)=$trans->transform($tree);

=head1 DESCRIPTION

This module allows you to transform tree with Perl subroutines, just
like XSLT does for XML documents.

It tries to model as closely as reasonable the semantic of XSLT.

=head1 REQUIREMENTS

By default, this module uses L<Tree::XPathEngine> as its XPath engine,
but you can use any other similar module, provided it implements the
method C<findnodes> with the same signature and
meaning. L<XML::XPathEngine> is a good candidate, or you could use
L<XML::LibXML::XPathContext>.

The tree that you intend to manipulate must be implemented by classes
that are compatible with the XPath engine; for example,
L<Tree::DAG_Node::XPath> if you use L<Tree::XPathEngine>, or
L<HTML::TreeBuilder::XPath> if you use L<XML::XPathEngine>.

=head1 EXPORTS

=head2 C<tree_rule>

  tree_rule match => '//node_name',
            priority => 1,
            action => sub { ... };

This is the basic fuction to declare a transformation rule; it's
equivalent to the C<template> element is XSLT. It takes its parameters
as a hash:

=over 4

=item C<match>

this is equivalent to the C<match> attribute of C<template>: it
specifies the pattern for the nodes to which this rule applies.

From the L<XSLT spec|http://www.w3.org/TR/xslt.html#NT-Pattern>:

I<A pattern is defined to match a node if and only if there is a
possible context such that when the pattern is evaluated as an
expression with that context, the node is a member of the resulting
node-set. When a node is being matched, the possible contexts have a
context node that is the node being matched or any ancestor of that
node, and a context node list containing just the context node.>

=item C<name>

this is equivalent of the C<name> attribute of C<template>: it allows
calling rules by name (see
L<call_rule|Tree::Transform::XSLTish::Transformer/call_rule>)

=item C<priority>

this is equivalent of the C<priority> attribute of C<template>;
currently the "default priority" as specified in the
L<spec|http://www.w3.org/TR/xslt.html#conflict> is not implemented

=item C<action>

this code-ref will be called (in list context) when the rule is to be
applied; it can return whatever you want:
L<call_rule|Tree::Transform::XSLTish::Transformer/call_rule> will
return the result unchanged,
L<apply_rules|Tree::Transform::XSLTish::Transformer/apply_rules> will
return the list of all results of all the applied rules

=back

The C<action> code-ref will be called (by
L<apply_rules|Tree::Transform::XSLTish::Transformer/apply_rules> or
L<call_rule|Tree::Transform::XSLTish::Transformer/call_rule>) with a
L<Tree::Transform::XSLTish::Transformer> object as its only parameter.

=head2 C<default_rules>

This function will declare two rules that mimic the implicit rules of
XSLT. It's equivalent to:

 tree_rule match => '/', priority => 0, action => sub {$_[0]->apply_rules};
 tree_rule match => '*', priority => 0, action => sub {$_[0]->apply_rules};

=head2 C<engine_class>

  engine_class 'XML::LibXML::XPathContext';

This function declares that the
L<Tree::Transform::XSLTish::Transformer> object returned by L</new>
should use this class to build its XPath engine.

This function is not exported by default: you have to use the module as:

 use Tree::Transform::XSLTish ':engine';

=head2 C<engine_factory>

  engine_factory { My::XPath::Engine->new(params=>$whatever) };

This function declares that the
L<Tree::Transform::XSLTish::Transformer> object returned by L</new>
should call the passed code-ref to get its engine.

C<engine_class $classname> is equivalent to C<< engine_factory {
$classname->new } >>.

This function is not exported by default: you have to use the module as:

 use Tree::Transform::XSLTish ':engine';

=head2 C<new>

Returns a L<Tree::Transform::XSLTish::Transformer> for the rules
declared in this package.

=head1 INHERITANCE

L<Stylesheet import|http://www.w3.org/TR/xslt.html#import> is implented
with the usual Perl inheritance scheme. It should even work with
L<Class::C3>, since we use L<Class::MOP>'s C<class_precedence_list> to
get the list of inherited packages.

Engine factories are inherited, too, so you can extend a rules package
without re-specifying the engine (you can, of course, override this
and specify another one).

=head1 IMPORTING

This module uses L<Sub::Exporter>, see that module's documentation for
things like renaming the imports.

=head1 KNOWN BUGS & ISSUES

=over 4

=item *

It's I<slow>. Right now each rule application is linear in the number
of defined rules I<times> the depth of the node being
transformed. There are several ways to optimize this for most common
cases (patches welcome), but I prefer to "make it correct, before
making it fast"

=item *

Some sugaring with L<Devel::Declare> could make everything look better

=back

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=cut
