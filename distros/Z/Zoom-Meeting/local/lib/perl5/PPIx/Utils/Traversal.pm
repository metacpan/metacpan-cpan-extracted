package PPIx::Utils::Traversal;

use strict;
use warnings;
use Exporter 'import';
use PPI::Token::Quote::Single;
use PPI::Document::Fragment;
use Scalar::Util 'refaddr';

use PPIx::Utils::Language qw(precedence_of);
use PPIx::Utils::_Common qw(
    is_ppi_expression_or_generic_statement
    is_ppi_simple_statement
);

our $VERSION = '0.003';

our @EXPORT_OK = qw(
    first_arg parse_arg_list split_nodes_on_comma
    get_next_element_in_same_simple_statement
    get_previous_module_used_on_same_line
    get_constant_name_elements_from_declaring_statement
    split_ppi_node_by_namespace
);

our %EXPORT_TAGS = (all => [@EXPORT_OK]);

# From Perl::Critic::Utils
my $MIN_PRECEDENCE_TO_TERMINATE_PARENLESS_ARG_LIST =
    precedence_of( 'not' );

sub first_arg {
    my $elem = shift;
    my $sib  = $elem->snext_sibling();
    return undef if !$sib;

    if ( $sib->isa('PPI::Structure::List') ) {

        my $expr = $sib->schild(0);
        return undef if !$expr;
        return $expr->isa('PPI::Statement') ? $expr->schild(0) : $expr;
    }

    return $sib;
}

sub parse_arg_list {
    my $elem = shift;
    my $sib  = $elem->snext_sibling();
    return() if !$sib;

    if ( $sib->isa('PPI::Structure::List') ) {

        #Pull siblings from list
        my @list_contents = $sib->schildren();
        return() if not @list_contents;

        my @list_expressions;
        foreach my $item (@list_contents) {
            if (
                is_ppi_expression_or_generic_statement($item)
            ) {
                push
                    @list_expressions,
                    split_nodes_on_comma( $item->schildren() );
            }
            else {
                push @list_expressions, $item;
            }
        }

        return @list_expressions;
    }
    else {

        #Gather up remaining nodes in the statement
        my $iter     = $elem;
        my @arg_list = ();

        while ($iter = $iter->snext_sibling() ) {
            last if $iter->isa('PPI::Token::Structure') and $iter eq ';';
            last if $iter->isa('PPI::Token::Operator')
                and $MIN_PRECEDENCE_TO_TERMINATE_PARENLESS_ARG_LIST <=
                    precedence_of( $iter );
            push @arg_list, $iter;
        }
        return split_nodes_on_comma( @arg_list );
    }
}

sub split_nodes_on_comma {
    my @nodes = @_;

    my $i = 0;
    my @node_stacks;
    for my $node (@nodes) {
        if (
                $node->isa('PPI::Token::Operator')
            and ($node eq ',' or $node eq '=>')
        ) {
            if (@node_stacks) {
                $i++; #Move forward to next 'node stack'
            }
            next;
        } elsif ( $node->isa('PPI::Token::QuoteLike::Words' )) {
            my $section = $node->{sections}->[0];
            my @words = split ' ', substr $node->content, $section->{position}, $section->{size};
            my $loc = $node->location;
            for my $word (@words) {
                my $token = PPI::Token::Quote::Single->new(q{'} . $word . q{'});
                $token->{_location} = $loc;
                push @{ $node_stacks[$i++] }, $token;
            }
            next;
        }
        push @{ $node_stacks[$i] }, $node;
    }
    return @node_stacks;
}

# From Perl::Critic::Utils::PPI
sub get_next_element_in_same_simple_statement {
    my $element = shift or return undef;

    while ( $element and (
            not is_ppi_simple_statement( $element )
            or $element->parent()
            and $element->parent()->isa( 'PPI::Structure::List' ) ) ) {
        my $next;
        $next = $element->snext_sibling() and return $next;
        $element = $element->parent();
    }
    return undef;

}

sub get_previous_module_used_on_same_line {
    my $element = shift or return undef;

    my ( $line ) = @{ $element->location() || []};

    while (not is_ppi_simple_statement( $element )) {
        $element = $element->parent() or return undef;
    }

    while ( $element = $element->sprevious_sibling() ) {
        ( @{ $element->location() || []} )[0] == $line or return undef;
        $element->isa( 'PPI::Statement::Include' )
            and return $element->schild( 1 );
    }

    return undef;
}
# End from Perl::Critic::Utils

# From PPIx::Utilities::Statement
my %IS_COMMA = ( q[,] => 1, q[=>] => 1 );

sub get_constant_name_elements_from_declaring_statement {
    my ($element) = @_;

    return() if not $element;
    return() if not $element->isa('PPI::Statement');

    if ( $element->isa('PPI::Statement::Include') ) {
        my $pragma;
        if ( $pragma = $element->pragma() and $pragma eq 'constant' ) {
            return _get_constant_names_from_constant_pragma($element);
        }
    } elsif ( not $element->specialized() and $element->schildren() > 2 ) {
        my $supposed_constant_function = $element->schild(0)->content();
        my $declaring_scope = $element->schild(1)->content();

        if (
                (
                        $supposed_constant_function eq 'const'
                    or  $supposed_constant_function =~ m< \A Readonly \b >x
                )
            and ($declaring_scope eq 'our' or $declaring_scope eq 'my')
        ) {
            return ($element->schild(2));
        }
    }

    return();
}

sub _get_constant_names_from_constant_pragma {
    my ($include) = @_;

    my @arguments = $include->arguments() or return();

    my $follower = $arguments[0];
    return() if not defined $follower;

    if ($follower->isa('PPI::Token::Operator') && $follower->content eq '+') {
        $follower = $arguments[1];
        return() if not defined $follower;
    }

    # We test for a 'PPI::Structure::Block' in the following because some
    # versions of PPI parse the last element of 'use constant { ONE => 1, TWO
    # => 2 }' as a block rather than a constructor. As of PPI 1.206, PPI
    # handles the above correctly, but still blows it on 'use constant 1.16 {
    # ONE => 1, TWO => 2 }'.
    if (
            $follower->isa( 'PPI::Structure::Constructor' )
        or  $follower->isa( 'PPI::Structure::Block' )
    ) {
        my $statement = $follower->schild( 0 ) or return();
        $statement->isa( 'PPI::Statement' ) or return();

        my @elements;
        my $inx = 0;
        foreach my $child ( $statement->schildren() ) {
            if (not $inx % 2) {
                push @{ $elements[ $inx ] ||= [] }, $child;
            }

            if ( $IS_COMMA{ $child->content() } ) {
                $inx++;
            }
        }

        return map
            {
                (
                        $_
                    and @{$_} == 2
                    and '=>' eq $_->[1]->content()
                    and $_->[0]->isa( 'PPI::Token::Word' )
                )
                    ? $_->[0]
                    : ()
            }
            @elements;
    } else {
        return ($follower);
    }

    return ($follower);
}
# End from PPIx::Utilities::Statement

# From PPIx::Utilities::Node
sub split_ppi_node_by_namespace {
    my ($node) = @_;

    # Ensure we don't screw up the original.
    $node = $node->clone();

    # We want to make sure that we have locations prior to things being split
    # up, if we can, but don't worry about it if we don't.
    eval { $node->location(); };

    if ( my $single_namespace = _split_ppi_node_by_namespace_single($node) ) {
        return $single_namespace;
    }

    my %nodes_by_namespace;
    _split_ppi_node_by_namespace_in_lexical_scope(
        $node, 'main', undef, \%nodes_by_namespace,
    );

    return \%nodes_by_namespace;
}

# Handle the case where there's only one.
sub _split_ppi_node_by_namespace_single {
    my ($node) = @_;

    my $package_statements = $node->find('PPI::Statement::Package');

    if ( not $package_statements or not @{$package_statements} ) {
        return { main => [$node] };
    }

    if (@{$package_statements} == 1) {
        my $package_statement = $package_statements->[0];
        my $package_address = refaddr $package_statement;

        # Yes, child and not schild.
        my $first_child = $node->child(0);
        if (
                $package_address == refaddr $node
            or  $first_child and $package_address == refaddr $first_child
        ) {
            return { $package_statement->namespace() => [$node] };
        }
    }

    return undef;
}


sub _split_ppi_node_by_namespace_in_lexical_scope {
    my ($node, $initial_namespace, $initial_fragment, $nodes_by_namespace)
        = @_;

    my %scope_fragments_by_namespace;

    # I certainly hope a value isn't going to exist at address 0.
    my $initial_fragment_address = refaddr $initial_fragment || 0;
    my ($namespace, $fragment) = ($initial_namespace, $initial_fragment);

    if ($initial_fragment) {
        $scope_fragments_by_namespace{$namespace} = $initial_fragment;
    }

    foreach my $child ( $node->children() ) {
        if ( $child->isa('PPI::Statement::Package') ) {
            if ($fragment) {
               _push_fragment($nodes_by_namespace, $namespace, $fragment);

                undef $fragment;
            }

            $namespace = $child->namespace();
        } elsif (
                $child->isa('PPI::Statement::Compound')
            or  $child->isa('PPI::Statement::Given')
            or  $child->isa('PPI::Statement::When')
        ) {
            my $block;
            my @components = $child->children();
            while (not $block and my $component = shift @components) {
                if ( $component->isa('PPI::Structure::Block') ) {
                    $block = $component;
                }
            }

            if ($block) {
                if (not $fragment) {
                    $fragment = _get_fragment_for_split_ppi_node(
                        $nodes_by_namespace,
                        \%scope_fragments_by_namespace,
                        $namespace,
                    );
                }

                _split_ppi_node_by_namespace_in_lexical_scope(
                    $block, $namespace, $fragment, $nodes_by_namespace,
                );
            }
        }

        $fragment = _get_fragment_for_split_ppi_node(
            $nodes_by_namespace, \%scope_fragments_by_namespace, $namespace,
        );

        if ($initial_fragment_address != refaddr $fragment) {
            # Need to fix these to use exceptions.  Thankfully the P::C tests
            # will insist that this happens.
            $child->remove() or die 'Could not remove child from parent.';
            $fragment->add_element($child) or die 'Could not add child to fragment.';
        }
    }

    return;
}

sub _get_fragment_for_split_ppi_node {
    my ($nodes_by_namespace, $scope_fragments_by_namespace, $namespace) = @_;

    my $fragment;
    if ( not $fragment = $scope_fragments_by_namespace->{$namespace} ) {
        $fragment = PPI::Document::Fragment->new();
        $scope_fragments_by_namespace->{$namespace} = $fragment;
        _push_fragment($nodes_by_namespace, $namespace, $fragment);
    }

    return $fragment;
}

# Due to $fragment being passed into recursive calls to
# _split_ppi_node_by_namespace_in_lexical_scope(), we can end up attempting to
# put the same fragment into a namespace's nodes multiple times.
sub _push_fragment {
    my ($nodes_by_namespace, $namespace, $fragment) = @_;

    my $nodes = $nodes_by_namespace->{$namespace} ||= [];

    if (not @{$nodes} or refaddr $nodes->[-1] != refaddr $fragment) {
        push @{$nodes}, $fragment;
    }

    return;
}
# End from PPIx::Utilities::Node

1;

=head1 NAME

PPIx::Utils::Traversal - Utility functions for traversing PPI documents

=head1 SYNOPSIS

    use PPIx::Utils::Traversal ':all';

=head1 DESCRIPTION

This package is a component of L<PPIx::Utils> that contains functions for
traversal of L<PPI> documents.

=head1 FUNCTIONS

All functions can be imported by name, or with the tag C<:all>.

=head2 first_arg

    my $first_arg = first_arg($element);

Given a L<PPI::Element> that is presumed to be a function call (which
is usually a L<PPI::Token::Word>), return the first argument.  This is
similar of L</parse_arg_list> and follows the same logic.  Note that
for the code:

    int($x + 0.5)

this function will return just the C<$x>, not the whole expression.
This is different from the behavior of L</parse_arg_list>.  Another
caveat is:

    int(($x + $y) + 0.5)

which returns C<($x + $y)> as a L<PPI::Structure::List> instance.

=head2 parse_arg_list

    my @args = parse_arg_list($element);

Given a L<PPI::Element> that is presumed to be a function call (which
is usually a L<PPI::Token::Word>), splits the argument expressions
into arrays of tokens.  Returns a list containing references to each
of those arrays.  This is useful because parentheses are optional when
calling a function, and PPI parses them very differently.  So this
method is a poor-man's parse tree of PPI nodes.  It's not bullet-proof
because it doesn't respect precedence. In general, I don't like the
way this function works, so don't count on it to be stable (or even
present).

=head2 split_nodes_on_comma

    my @args = split_nodes_on_comma(@nodes);

This has the same return type as L</parse_arg_list> but expects to be
passed the nodes that represent the interior of a list, like:

    'foo', 1, 2, 'bar'

=head2 get_next_element_in_same_simple_statement

    my $element = get_next_element_in_same_simple_statement($element);

Given a L<PPI::Element>, this subroutine returns the next element in
the same simple statement as defined by
L<PPIx::Utils::Classification/is_ppi_simple_statement>. If no next
element can be found, this subroutine simply returns C<undef>.

If the $element is undefined or unblessed, we simply return C<undef>.

If the $element satisfies
L<PPIx::Utils::Classification/is_ppi_simple_statement>, we return
C<undef>, B<unless> it has a parent which is a L<PPI::Structure::List>.

If the $element is the last significant element in its L<PPI::Node>,
we replace it with its parent and iterate again.

Otherwise, we return C<< $element->snext_sibling() >>.

=head2 get_previous_module_used_on_same_line

    my $element = get_previous_module_used_on_same_line($element);

Given a L<PPI::Element>, returns the L<PPI::Element> representing the
name of the module included by the previous C<use> or C<require> on
the same line as the $element. If none is found, simply returns
C<undef>.

For example, with the line

    use version; our $VERSION = ...;

given the L<PPI::Token::Symbol> instance for C<$VERSION>, this will
return "version".

If the given element is in a C<use> or <require>, the return is from
the previous C<use> or C<require> on the line, if any.

=head2 get_constant_name_elements_from_declaring_statement

    my @constants = get_constant_name_elements_from_declaring_statement($statement);

Given a L<PPI::Statement>, if the statement is a L<Readonly>, L<ReadonlyX>, or
L<Const::Fast> declaration statement or a C<use constant>, returns the names
of the things being defined.

Given

    use constant 1.16 FOO => 'bar';

this will return the L<PPI::Token::Word> containing C<'FOO'>.
Given

    use constant 1.16 { FOO => 'bar', 'BAZ' => 'burfle' };

this will return a list of the L<PPI::Token>s containing C<'FOO'> and C<'BAZ'>.
Similarly, given

    Readonly::Hash my %FOO => ( bar => 'baz' );

or

    const my %FOO => ( bar => 'baz' );

this will return the L<PPI::Token::Symbol> containing C<'%FOO'>.

=head2 split_ppi_node_by_namespace

    my $subtrees = split_ppi_node_by_namespace($node);

Returns the sub-trees for each namespace in the node as a reference to a hash
of references to arrays of L<PPI::Node>s.  Say we've got the following code:

    #!perl

    my $x = blah();

    package Foo;

    my $y = blah_blah();

    {
        say 'Whee!';

        package Bar;

        something();
    }

    thingy();

    package Baz;

    da_da_da();

    package Foo;

    foreach ( blrfl() ) {
        ...
    }

Calling this function on a L<PPI::Document> for the above returns a
value that looks like this, using multi-line string literals for the
actual code parts instead of PPI trees to make this easier to read:

    {
        main    => [
            q<
                #!perl

                my $x = blah();
            >,
        ],
        Foo     => [
            q<
                package Foo;

                my $y = blah_blah();

                {
                    say 'Whee!';

                }

                thingy();
            >,
            q<
                package Foo;

                foreach ( blrfl() ) {
                    ...
                }
            >,
        ],
        Bar     => [
            q<
                package Bar;

                something();
            >,
        ],
        Baz     => [
            q<
                package Baz;

                da_da_da();
            >,
        ],
    }

Note that the return value contains copies of the original nodes, and not the
original nodes themselves due to the need to handle namespaces that are not
file-scoped.  (Notice how the first element for "Foo" above differs from the
original code.)

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

Code originally from L<Perl::Critic::Utils> by Jeffrey Ryan Thalhammer
<jeff@imaginative-software.com>, L<Perl::Critic::Utils::PPI> and
L<PPIx::Utilities::Node> by Elliot Shank <perl@galumph.com>, and
L<PPIx::Utilities::Statement> by Thomas R. Wyant, III <wyant@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2011 Imaginative Software Systems,
2007-2011 Elliot Shank, 2009-2010 Thomas R. Wyant, III, 2017 Dan Book.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<Perl::Critic::Utils>, L<Perl::Critic::Utils::PPI>, L<PPIx::Utilities>
