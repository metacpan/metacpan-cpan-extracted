package XML::Filter::Dispatcher::Ops;

=head1 NAME

XML::Filter::Dispatcher::Ops - The Syntax Tree

=head1 SYNOPSIS

    None.  Used by XML::Filter::Dispatcher.

=cut

## TODO: Replace XFD:: with XML::Filter::Dispatcher

## TODO: "helper" subs.  functions?  dunno.
## as-structure() EventPath function
## emit XML chunk (well balanced, not wf)
## as_document

## TODO: use context->{PossibleEventTypes} to
## reduce the amount of downstream test code and
## perhaps the amount of currying.  No need to test
## for EventType if we know only one node type is
## possible :).

package XFD;

use Carp qw( confess );  ## NOT croak: this module must die "...\n".

use constant is_tracing => defined $Devel::TraceSAX::VERSION;

# Devel::TraceSAX does not work with perl5.8.0
#use constant is_tracing => 1;
#sub emit_trace_SAX_message { warn @_ };

## Some debugging aids
*_ev = \&XML::Filter::Dispatcher::_ev;
*_po = \&XML::Filter::Dispatcher::_po;

BEGIN {
    eval( is_tracing
        ? 'use Devel::TraceSAX qw( emit_trace_SAX_message ); 1'
        : 'sub emit_trace_SAX_message; 1'
    ) or die $@;

}

use strict;

use vars ( 
    '$dispatcher',        ## The X::F::D that we're doing the parse for.
);

=begin private

=head1 Precursors and Postponment

NOTE: in this blurb, nodes occur in alphabetical order in the document
being processed.

level 0 expressions are able to be evaluated using only the current
event and it's 'ancestor events' and, when the match succeeds, the
action is executed in the current event's context.  The path '/a/b[@c]'
is level 0 can be evaluated using just the start_document event and the
start_element events for <a>, <b>, and <c>.  So are the paths
'/a[@a]/b[@b]/c' and '/a[b]/b[c]/c'.

The paths '/a[b]' is not level 0; it requires some evaluation to occur
when the start_element event for '/a' is seen and other evaluation when
the start_element event for '/a/b' is seen; and when it does match
(which will occur in the start event for the first '/a/b'), the action's
execution context must be '/a', not '/a/b'.  In this case, the match
must proceed in stages and the action is postponed until all stages are
satisfied.

This is implemented in this code by converting level 1 expressions in to
precursors ('/a' and './b' in /a's context in our example) and
postponing the main expression (which just fires the action in this
case) using an object called a "postponement session" until enough
precursors are satisfied.  Once enough precursors are satisfied, the
action is executed and the postponement is destroyed.

The phrase "enough precursors are satisfied" is used rather than "all
precursors are satisfied" because expressions like 'a[ b or c ]' does
not need both the './b' or './c' precursors; either one will suffice.

A postponement session has a value slot for each precursor and a slot for
the result context.  Each precursor fills is it's slot when it matches,
and the primary precursor sets the main expression / action context.  As
each precursor fires, it checks to see if enough of the slots are filled
in and fires the action or main expression if so.  Expressions like
'//*[b]' and '/a//b[c]' can cause multiple simultaneous postponement
sessions for the same expression.

For expressions like '/a/b[c]/d', the main expression (or result)
context may not be set when some of the precursors match: /a/b/c will
match before /a/b/d.  The precursor for '/a/b/d' is called the primary
precursor and sets the result context.

The action (or main expression in an expression line '/a[concat(b,c)]') is
evaluated in the result context ('/a' in this case).

The main expression (or action) should be executed once per primary
precursor match in the document where the entire expression is true.
So a rule with a pattern '/a/b[c]/d[e]' would fire once for every /a/b/d
node in the document where the entire match is true.

//a[b]/c and //a[c]/b

The first precursor to match must create a postponement session.

Q: How do we associate the precursors with their appropriate
postponement sessions?

In expressions like 'concat( /a, /b )', the precursors '/a' and '/b' are
numbered 0 and 1 and there is a "main expression" of 'concat(
PRECURSOR_0, PRECURSOR_1)', where the PRECURSOR_# is the result of the
indicated precursor.  The main expression which is computed before
firing the action.  The action context is "/".

Expressions like 'concat( a, b )' are similar except that the action
context is the parent of the <a> and <b> elements that match.

In '/a[concat( b, c )]' the precursors are './b', './c' and 'a[concat(
PRECURSOR_0, PRECURSOR_1 )]', and the action can only fire when
PRECURSOR_2 becomes defined.  The action contexst is '/a'.

Each time a context-setting precursor matches, all presursor sessions
that it affects become "eligible" for firing.  A precursor session fires
as soon as enough precursors are satisfied.

=head2 Firing Policy

This does not apply to level 0 patterns.

An application may support multiple policies controlling when a
postponed expression is finally completely evaluated (ie matches, fails
to match, or returns a result).

A "prompt evaluation policy" describes implementations where postponed
expressions match the first time enough predicates are
satisified (when the <b> start_element() arrives, in this case).  This
is useful to minimize memory and recognize conditions as rapidly as
possible.

A "delayed evaluation policy" describes implementations where postponed
expressions are evaluated during the end_...() event for the node
deepest in the hierarchy for which an un-postponed test was true.  For
example, rules with these patterns must fire their actions before the
</a> if at all: '/a[b]', '/z/a/[b]'.   This may make some
implementations easier but is discouraged unless necessary.

An application must be apply a consistent firing policy policy prompt, 

An application may also provide for 

An application must detail whether it supports modes other than "prompt
firing" or not and all applications 

=end private

=cut

###############################################################################
##
## Boolean Singletons
##

## These are not used internally; 1 and 0 are.  These are used when passing
## boolean values in / out to Perl code, so they may be differentiated from
## numeric ones.
sub true()  { \"true"  }
sub false() { \"false" }


###############################################################################
##
## Helpers
##
sub _looks_numeric($)  { $_[0] =~ /^[ \t\r\n]*-?(?:\d+(?:\.\d+)?|\.\d+)[ \t\r\n]*$/ }

sub _looks_literal($)  { $_[0] =~ /^(?:'[^']*'|"[^"]*")(?!\n)\Z/       }

sub _indentomatic() { 1 }  ## Turning this off shaves a little parse time.
                           ## I leave it on for more readable error
                           ## messages, and it's key for debugging since
                           ## is so much more readable; in fact, messed
                           ## up indenting can indicate serious problems

sub _indent { Carp::confess "undef" unless defined $_[0]; $_[0] =~ s/^/  /mg; }

sub _is_rel_path($) {
    my $path = shift;

    return 0
        if $path->isa( "XFD::PathTest" )
            && $path->isa( "XFD::doc_node" )                  ## /... paths
            && ! $path->isa( "XFD::union" ); ## (a|b), union called this already.

    return 1;
}


###############################################################################
##
## Postponement Records
##
## When the current location step or operator/function call
## in an expression can't be calculated because it needs some
## future information, it must be postponed.  The portions of
## the expression that can't yet be calculated are called
## precursors; only when enough of them are calculated can
## this expression be calculated.
##
## A Postponement record contains:
##
## - A list of contexts for which this postponement eventually
##   becomes valid.
## - A pointer to the parent postponement
## - A set of results one for each precursor.
##
## A postponement record is a simple array with a few set data fields
## in the first elements; the remaining elements are used to hold
## precursor results.
##
## This could be an object, but we don't need any inheritence.
##
sub _p_parent_postponement() { 0 }
sub _p_contexts()            { 1 }
sub _p_first_precursor ()    { 2 }

###############################################################################
##
## expr_as_incr_code
##

##
## Precursors
## ==========
##
## A precursor is something (so far always a location path sub-expr) that
## (usually) needs to be dealt with before a pattern can be evaluated.
## A precursor is known as "defined" if it's been evaluated and returned
## some result (number, string, boolean, or node).
##
## The only time a pattern can be fully evaluated in the face of undefined
## precursor is when the precursor is supposed to return a node and the
## precursor result is being turned in to a boolean.  Booleans accept
## empty node sets as false values.  Right now, all precursors happen to
## return node sets of 0 or 1 nodes.
##
## The precursor values are stored in $ctx because I'm afraid of leaky
## closure in older perl.  I haven't tested them in this case, but have been
## bit before.

sub _replace_NEXT {
    my $what_next = "<NEXT>";
    $what_next = pop if @_ > 2;
    my $next_code = pop;
    $_[0] =~ s{(^[ \t]*)?$what_next}{
        if ( _indentomatic && defined $1 ) {
            _indent $next_code for 1..(length( $1 ) / 2 );
        }
        $next_code
    }gme;
}


###############################################################################
##
## Parse tree node base class
##
## This is used for all of the pieces of location paths axis tests, name
## and type tests, predicates.  It is also used by a few functions
## that act on the result of a location path (which is effectively a
## node set with just the current node in it).
##
sub XFD::Op::new {
    my $class = shift;
    return bless [ @_ ], $class;
}


sub XFD::Op::op_type { ( my $type = ref shift ) =~ s/.*:// ; $type }

## The optimizer combines common expressions in some cases (it should
## do more, right now it only does common leading op codes).  To do this
## it needs to know the type of the operator and its arguments, if any.
## By default, the signature is this op's reference id, which makes each
## op look different to the optimizer.
sub XFD::Op::optim_signature { int shift }


sub XFD::Op::is_constant {
    my $self = shift;
    return ! grep ! $_->is_constant, @$self;
}
 
## fixup is called on a freshly parsed op tree just before it's
## compiled to convert expression like 'A' to be like '//A'.
## TODO: Perhaps move this to an XML::Filter::Dispatcher::_fixup(),
## like _optimize().
sub XFD::Op::fixup {
    my $self = shift;
    my ( $context ) = @_;

    for ( @$self ) {
        if ( defined && UNIVERSAL::isa( $_, "XFD::Op" ) ) {
            if ( ! $context->{BelowRoot}
                && ( $_->isa( "XFD::Axis::child" )
                    || $_->isa( "XFD::Axis::attribute" )
                    || $_->isa( "XFD::Axis::start_element" )
                    || $_->isa( "XFD::Axis::end_element" )
#                    || $_->isa( "XFD::Axis::end" )
                )
            ) {
                ## The miniature version of XPath used in
                ## XSLT's <template match=""> match expressions
                ## seems to me to behave like // was prepended if
                ## the expression begins with a child:: or
                ## attribute:: axis (or their abbreviations: no
                ## axis => child:: and @ => attribute::).
                my $op = XFD::EventType::node->new;
                $op->set_next( $_ );
                $_ = $op;
                $op = XFD::Axis::descendant_or_self->new;
                $op->set_next( $_ );
                $_ = $op;
                $op = XFD::doc_node->new;
                $op->set_next( $_ );
                $_ = $op;
            }

            ## This statement is why the descendant-or-self:: insertion
            ## is done in Op::fixup instead of Rule::fixup.  We want
            ## this transform to percolate down to the first op of each
            ## branch of these "grouping" ops.
            local $context->{BelowRoot} = 1
                unless $_->isa( "XFD::Parens" )
                    || $_->isa( "XFD::union" )
                    || $_->isa( "XFD::Action" )
                    || $_->isa( "XFD::Rule" );

            $_->fixup( @_ );
        }
    }

    return $self;
}


sub XFD::Op::_add_to_graphviz {
    my $self = shift;
    my ( $g ) = @_;

    my $port_id = 0;

    my $port_labels = join( "|",
        map {
            my $desc = ref $_
                ? $self->can( "parm_type" )
                    ? $self->parm_type( $port_id - 1 )
                    : UNIVERSAL::can( $_, "_add_to_graphviz" )
                        ? ""
                        : ref $_
                : defined $_
                    ? do {
                        local $_ = $_;
                        "'$_'"
                    }
                    : "undef"
            ;
            for ( $desc ) {
                s/([|<>\[\]{}"])/\\$1/g;
                s/\n/\\\\n/g;
                s/(.{64}).*/$1.../;
            }
            "<port" . $port_id++ . ">" . $desc;
        } @$self
    );

    my $label = join( "",
        "{",
        $self->op_type,
        $self->isa( "XFD::Action" ) && $self->[0]->{DelayToEnd}
            ? " (end::)"
            : (),
        $port_labels eq "<port0>"
            ? ()
            : ( "|{", $port_labels, "}" ),
        "}"
    );

    $g->add_node(
        shape    => "record",
        name     => int $self,
        label    => $label,
        color    => $self->is_constant    ? "blue"
            : $self->isa( "XFD::Action" ) ? "#A00000"
                                          : "black",
        height   => 0.1,
        fontname => "Helvetica",
        fontsize => 10,
    );

    $port_id = 0;
    for ( @$self ) {
        if ( UNIVERSAL::can( $_, "_add_to_graphviz" ) ) {
            $_->_add_to_graphviz( $g );
            $g->add_edge( {
                from      => int $self,
                $port_labels eq "<port0>"
                    ? ()
                    : ( from_port => $port_id ),
                to        => int $_,
            } );
        }
        ++$port_id;
    }
}

sub XFD::Op::as_graphviz {
    my $self = shift;
    my $g  = @_ ? shift : do {

        require GraphViz;
        my $g = GraphViz->new(
            nodesep => 0.1,
            ranksep => 0.1,
        );
    };

    $self->_add_to_graphviz( $g );

    return $g;
}

###############################################################################
##
## Numeric and String literals
##
@XFD::NumericConstant::ISA = qw( XFD::Op );
sub XFD::NumericConstant::result_type   { "number" }
sub XFD::NumericConstant::is_constant   { 1 }
sub XFD::NumericConstant::as_immed_code { shift->[0] }

@XFD::StringConstant::ISA = qw( XFD::Op );
sub XFD::StringConstant::result_type   { "string" }
sub XFD::StringConstant::is_constant   { 1 }
sub XFD::StringConstant::as_immed_code { 
    my $s = shift->[0];
    $s =~ s/([\\'])/\\$1/g;
    return join $s, "'", "'";
}

################################################################################
##
## Compile-time constant folding
##
## By tracking what values and expressions are constant, we can use
## eval "" to evaluate things at compile time.
##
sub _eval_at_compile_time {
    my ( $type, $code, $context ) = @_;

    return $code unless $context->{FoldConstants};

    my $out_code = eval $code;
    die "$@ in XPath compile-time execution of ($type) \"$code\"\n"
        if $@;

    ## Perl's bool ops ret. "" for F
    $out_code = "0"
        if $type eq "boolean" && !length $out_code;
    $out_code = $$out_code if ref $out_code;
    if ( $type eq "string" ) {
        $out_code =~ s/([\\'])/\\$1/g;
        $out_code = "'$out_code'";
    }

    #warn "compiled `$code` to `$out_code`";
    return $out_code;
}

###############################################################################
##
## PathTest base class
##
## This is used for all of the pieces of location paths axis tests, name
## and type tests, predicates.  It is also used by a few functions
## that act on the result of a location path (which is effectively a
## node set with just the current node in it).
##
@XFD::PathTest::ISA = qw( XFD::Op );


## TODO: factor som/all of this in to possible_event_types().
## That could die with an error if there are no possible event types.
## Hmmm, may also need to undo the oddness that a [] PossibleEventTypes
## means "any" (that's according to a comment, need to verify that
## the comment does not lie).

sub XFD::PathTest::check_context {
    my $self = shift;
    my ( $context ) = @_;

    my $hash_name = ref( $self ) . "::AllowedAfterAxis";

    no strict "refs";
    die "'", $self->op_type, "' not allowed after '$context->{Axis}'\n"
        if keys %{$hash_name}
            && exists ${$hash_name}{$context->{Axis}};

    ## useful_event_contexts are the events that are useful for a path
    ## test to be applied to.  If the context does not have one of these
    ## in it's PossibleEventTypes, then it's a useless (never-match)
    ## expression.  For now, we die().  TODO: warn, but allow the
    ## warning to be silenced.

    if ( $self->can( "useful_event_contexts" )
        && defined $context->{PossibleEventTypes}
        && @{$context->{PossibleEventTypes}} ## empty list = "any".
    ) {
        my %possibles = map {
            ( $_ => undef );
        } @{$context->{PossibleEventTypes}};

        my @not_useful; my @useful;

        for ( $self->useful_event_contexts ) {
            exists $possibles{$_}
                ? push @useful, $_
                : push @not_useful, $_;
        }

#warn $context->{PossiblesSetBy}->op_type, "/", $self->op_type, " NOT USEFUL: ", join( ",", @not_useful ), "  (useful: ", join( ",", @useful ), ")\n" if @not_useful;
        die 
            $context->{PossiblesSetBy}->op_type,
            " (which can result in ",
            @{$context->{PossibleEventTypes}}
                ? join( ", ", @{$context->{PossibleEventTypes}} ) . (
                    @{$context->{PossibleEventTypes}} > 1
                        ? " event contexts"
                        : " event context"
                )
                : "any event context",
            ") followed by ",
            $self->op_type,
            " (which only match ",
            join( ", ", $self->useful_event_contexts ),
            " event types)",
            " can never match\n"
            unless @useful;
    }
}

sub XFD::PathTest::new { shift->XFD::Op::new( @_, undef ) }

sub XFD::PathTest::is_constant { 0 }
sub XFD::PathTest::result_type { "nodeset" }

sub _next() { -1 }

## This next one is used by external code like the optimizer,
## not by this module.
sub XFD::PathTest::get_next { $_[0]->[_next] }
sub XFD::PathTest::force_set_next { $_[0]->[_next] = $_[1] }

sub XFD::PathTest::optim_signature {
    my $self = shift;
    return join "",
        ref( $self ), "(", defined $self->[0] ? "'$self->[0]'" : "undef", ")";
}



sub XFD::PathTest::set_next {
    my $self = shift;
Carp::confess "undef!" unless defined $_[0];
    if ( $self->[_next] ) {
        # Unions cause this method to be called multiple times
        # and we never want to have a loop.
        return if $self          == $_[0];
        return if $self->[_next] == $_[0];
Carp::confess "_next ($self->[_next]) can't set_next" unless $self->[_next]->can( "set_next" );
        $self->[_next]->set_next( @_ );
    }
    else {
        $self->[_next] = shift;
    }
}

## A utility function required by node_name and namespace_test to parse
## prefix:localname strings.
sub XFD::PathTest::_parse_ns_uri_and_localname {
    my $self = shift;
    my ( $name ) = @_;

    my ( $prefix, $local_name ) =
        $name =~ /(.*):(.*)/
            ? ( $1, $2 )
            : ( "", $name );

    my $uri = exists $dispatcher->{Namespaces}->{$prefix}
        ? $dispatcher->{Namespaces}->{$prefix}
        : length $prefix
            ? die "prefix '$prefix' not declared in Namespaces option\n"
            : "";
        
    die "prefix '$prefix:' not defined in Namespaces option\n"
        unless defined $uri;

    return ( $uri, $local_name );
}

## child:: and descendant-or-self:: axes need to curry to child nodes.
## These tests are the appropriate tests for child nodes.
my %child_curry_tests = qw( start_element 1 comment 1 processing_instruction 1 characters 1 );

## No need for DocSubs in this array; we never curry to a doc node event
## because doc node events never occur inside other nodes.
my @all_curry_tests = qw( start_element comment processing_instruction characters attribute namespace );

## TODO: Detect when an axis tries to queue a curried test on to a particular
## FooSubs, and that test is incompatible with the axis.  Not sure how
## important that is, but I wanted to note it here for later thought.

sub XFD::PathTest::curry_tests {
    ## we assume that there will *always* be a node test after an axis.
    ## This is a property of the grammar.
    my $self = shift;
    my $next = $self->[_next];
    Carp::confess "$self does not have a next" unless defined $next;
    return $next->curry_tests;
}



sub XFD::PathTest::insert_next_in_to_template {
    my $self = shift;
    my ( $template, $next_code ) = @_;

    my ( $preamble, $postamble ) = split /<NEXT>/, $template, 2;
    return $preamble unless defined $postamble;

    if ( _indentomatic && $preamble =~ s/( *)(?!\n)\Z// ) {
        _indent $next_code for 1.. length( $1 ) / 2
    }
    return join $next_code, $preamble, $postamble;
}


sub XFD::PathTest::possible_event_types {
    my $self = shift;
    my ( $context ) = @_;

    my $possibles = $self->possible_event_type_map( @_ );

    my %seen;
    my @possibles = grep !$seen{$_}++,
        map exists $possibles->{$_} ? @{$possibles->{$_}} : (),
            @{$context->{PossibleEventTypes}};

    return @possibles;
}

## "Incremental code" gets evaluated SAX event by SAX event, currying it's
## results until future events are received if need be.
sub XFD::PathTest::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;

    $self->check_context( $context );

    ## This is the moral equivalent to the principal node type
    ## from XPath.  Always set by axes.
    local $context->{PrincipalEventType} = $self->principal_event_type
        if $self->can( "principal_event_type" );

    ## These are the types of events that can make it through a
    ## path test to the next test.  Usually (always?) set by axes.
    ## right now an empty array means "any".
    ## TODO: make sure this is set as accurately as possible; the
    ## more accurately this is set, the more often we can give
    ## helpful errors.
    ## For instance, in non-currying axes, the current set of
    ## possibles needs to be intersected with this axis' set
    ## of possibles.
    my $set_possibles = $self->can( "possible_event_type_map" );
#warn $self->op_type, ",", $set_possibles;
    local $context->{PossibleEventTypes} = [ $self->possible_event_types( @_ ) ]
        if $set_possibles;
    local $context->{PossiblesSetBy} = $self
        if $set_possibles;
    confess "BUG: No _next op and no ActionCode"
        unless $self->[_next] || $context->{ActionCode};

    $self->insert_next_in_to_template(
        $self->incr_code_template( $context ),
        $self->[_next]
            ? $self->[_next]->as_incr_code( $context )
            : $context->{ActionCode}
    );
}


## "Immediate code" gets evaluated as the expression is evaluated, so
## it must perform DOM walking (we have only a minimal DOM: non-children
## of elt nodes: attrs and namespace nodes).
##
## ARRAY actions are only possible when handed in from outside.  Since
## immediate code is only used inside function parameters and predicates,
## it should be impossible for now to see an ARRAY action here.
##
sub XFD::PathTest::as_immed_code {
    my $self = shift;

    return $self->insert_next_in_to_template(
        $self->immed_code_template( @_ ),
        $self->[_next] ? $self->[_next]->as_immed_code( @_ ) : ""
    );
}


sub XFD::PathTest::immed_code_template {
    ## Some axes (forward and descendant) need to be precursorized
    ## when in function calls and expressions.  munge_parms catches
    ## this and does the precursorization shuffle.
    die "precursorize THIS\n";
}

###############################################################################
## An ExprEval masqeurades as a PathTest so it can be slapped on to the
## end of a PathTest.  But really, it evaluates the expression and saves
## the result, then fires the action code.
   @XFD::ExprEval::ISA = qw( XFD::PathTest );
sub XFD::ExprEval::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;

    my $boolerizer = "";
    $boolerizer = " ? true : false"
        if $self->[0]->result_type eq "boolean";

    my $action_ops = $self->[_next];

    my $action_id = $action_ops->action_id;

    local $context->{SetXValuesEntry} = 1;

    my $expr_code = get_expr_code( "", $self->[0], <<CODE_END, $self->[_next], undef, @_ );
## expression evaluation
\$ctx->{XValues}->[$action_id] = <EXPR>$boolerizer;
emit_trace_SAX_message "EventPath: xvalue set to '\$ctx->{XValues}->[$action_id]' for event ", _ev \$ctx if is_tracing;
<NEXT>
# end expression evaluation
CODE_END

    return $expr_code;
}

###############################################################################
##
## Actions
##

## If the action is in an op tree that's being precursorized, it needs
## to return an alternate bit of Perl code (one that sets the precursor)
## and queue up the action code to be run when enough precursors are
## defined and the expression is true.
   @XFD::Action::ISA = qw( XFD::Op );
sub XFD::Action::result_type { Carp::confess "Actions have no result types" }
sub XFD::Action::is_constant { 0 }
sub XFD::Action::curry_tests { return @all_curry_tests }

sub XFD::Action::action_code  { return shift->[0]->{Code}  }
sub XFD::Action::action_id    { return shift->[0]->{Id}    }
sub XFD::Action::action_score { return shift->[0]->{Score} }

sub XFD::Action::fixup {
    my $self = shift;
    my ( $context ) = @_;
    $self->[0]->{DelayToEnd} = $context->{DelayToEnd};
}

sub XFD::Action::gate_action {
    my $self = shift;
    my $action_code = shift;
    my ( $context ) = @_;

    my $id    = $self->action_id;
    my $score = $self->action_score;

    my ( $now_or_later, $s ) =
        $self->[0]->{DelayToEnd} && ! $context->{IgnoreDelayToEnd}
        ? ( "PendingEndActions", "pending end action" )
        : ( "PendingActions", "pending action" );

    unless ( $context->{CallActionDirectly} ) {
        _indent $action_code if _indentomatic;
        $action_code = <<CODE_END 
sub { ## action
$action_code}
CODE_END
    }

    $action_code = <<CODE_END;
emit_trace_SAX_message "adding $s $score for event ", _ev \$ctx if is_tracing;
push \@{\$ctx->{$now_or_later}->{$score}}, $action_code;
CODE_END


    if ( defined $context->{action_wrapper} ) {
        my $foo = $context->{action_wrapper};
        _replace_NEXT $foo, $action_code, "<ACTION>";
        $action_code = $foo;
    }

    return $action_code unless defined $context->{precursorize_action};

    push @{$context->{precursorized_action_codes}}, $action_code;
    return $context->{precursorize_action};
}


##########
   @XFD::Action::PerlCode::ISA = qw( XFD::Action );
sub XFD::Action::PerlCode::as_incr_code  {
    my $self = shift;
    my ( $context ) = @_;
Carp::confess unless @_;
    my $action_code = $self->action_code;

    my $action_id = $self->action_id;

    my $xvalue_expr = "";
    if ( $dispatcher->{SetXValue} ) {
        $xvalue_expr = $context->{SetXValuesEntry}
            ? "local \$d->{XValue} = \$ctx->{XValues}->[$action_id];\n"
            : "local \$d->{XValue} = \$ctx->{Node};\n";
    }

    local $context->{CallActionDirectly} = 1
        unless length $xvalue_expr;
    $action_code =~ s/->\(\s*\@_\s*\)//
        unless length $xvalue_expr;

    return $self->gate_action( "$xvalue_expr$action_code", $context ) ;
}

sub XFD::Action::PerlCode::as_immed_code {
    goto \&XFD::Action::PerlCode::as_incr_code;
}
##########
   @XFD::SubRules::ISA = qw( XFD::Op );
sub XFD::SubRules::curry_tests {
    my $self = shift;

    my %tests;

    for ( @$self ) {
        for ( $_->curry_tests ) {
            $tests{$_} = undef;
        }
    }

    return keys %tests;
}

sub XFD::SubRules::as_incr_code {
    my $self = shift;

    my @code;
    my $i = 0;
    for ( @$self ) {
        my $code = $_->as_incr_code( @_ );
        _indent $code if _indentomatic;
        push @code, "## SubRule $i\n$code## end SubRule $i\n";
        ++$i;
    }
    join "", @code;
}

sub XFD::SubRules::as_immed_code {
    die "The result of an EventPath expression cannot be forwarded to sub rules\n";
}
##########
   @XFD::Action::EventForwarder::ISA = qw( XFD::Action );
sub XFD::Action::EventForwarder::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;
Carp::confess unless @_;

    my $new_handler_expr = $self->action_code;
    my $action_score     = $self->action_score;

    my $forward_end_event_too =
        grep /^start_/, @{$context->{PossibleEventTypes}};

    my $end_event_forwarding_code = "";
    if ( $forward_end_event_too ) {
        $end_event_forwarding_code = <<CODE_END;
  emit_trace_SAX_message "EventPath: queuing end_ action for \$event_type event ", _ev \$ctx if is_tracing;
  push \@{\$ctx->{PendingEndActions}->{$action_score}}, sub {
    emit_trace_SAX_message "EndSub end_ action for ", _ev \$ctx if is_tracing;
    my \$h = $new_handler_expr;
    my \$event_type = \$ctx->{EventType};
    \$d->{LastHandlerResult} = \$h->\$event_type( \$ctx->{Node} );
  };
CODE_END

        if ( grep !/^start_/, @{$context->{PossibleEventTypes}} ) {
            _indent $end_event_forwarding_code if _indentomatic;
            $end_event_forwarding_code = <<CODE_END;
  if ( substr( \$event_type, 0, 6 ) eq "start_" ) {
$end_event_forwarding_code  }
CODE_END
        }
    }

    ## TODO: only forward end events if this op's not in start-element::
    ## or end-element:: context and is intercepting a start_document or
    ## start_element.
    return $self->gate_action( <<CODE_END, $context );
{
  my \$event_type = \$ctx->{EventType};
  my \$h = $new_handler_expr;

  if ( ! \$d->{DocStartedFlags}->{\$h} ) {
    \$d->{DocStartedFlags}->{\$h} = 1;
    if ( \$event_type ne "start_document"
      && ! \$d->{SuppressAutoStartDocument}
    ) {
      push \@{\$d->{AutoStartedHandlers}}, \$h;
      \$h->start_document( {} );
    }
  }

  \$d->{LastHandlerResult} = \$h->\$event_type( \$ctx->{Node} );
$end_event_forwarding_code}
CODE_END
}

sub XFD::Action::EventForwarder::as_immed_code {
    ## TODO: make it so node-set returning functions can be.
    ## TODO: Allow other things to be forwarded as characters()
    die "The result of an EventPath expression cannot be forwarded to a SAX handler\n";
}

##########
   @XFD::Action::EventCutter::ISA = qw( XFD::Action );
sub XFD::Action::EventCutter::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;

    my $cut_list_expr = $self->action_code;

    ## TODO: only forward trees if this op's not in start-element::
    ## or end-element:: context and is intercepting a start_document or
    ## start_element.
    return $self->gate_action( <<CODE_END, $context );
if ( is_tracing ) {
  my \$c = $cut_list_expr;
  for my \$h ( \@\$c ) {
    emit_trace_SAX_message "EventPath: cutting from handler \$h" if is_tracing;
  }
}
CODE_END
}

sub XFD::Action::EventCutter::as_immed_code {
    ## TODO: make it so node-set returning functions can be.
    ## TODO: Allow other things to be forwarded as characters()
    die "The result of an EventPath expression cannot be forwarded to a SAX handler\n";
}

##########
sub action {
    my $action = shift;

    my $action_type = ref $action ;

    if ( $action_type eq "ARRAY" ) {
        ## It's s nested list of rules.
        my @rules = @$action;

        die "Odd number of elements in action ARRAY\n"
            if @rules % 1;
        
        my @action_ops;
        while ( @rules ) {
            my ( $expr, $action ) = ( shift @rules, shift @rules );
            push @action_ops, XML::Filter::Dispatcher::Parser->_parse(
                $expr,
                $action,
                $dispatcher, ## TODO: pass options here.
            );
        }
        
        return XFD::SubRules->new( @action_ops );
    }

    ## It's a real action, not a set of subrules.

    push @{$dispatcher->{Actions}}, my $a_hash = {};
    my $action_num = $#{$dispatcher->{Actions}};
    $a_hash->{Id} = $action_num;

    ## TODO: Allow a HASH to be passed in so the caller can set the score
    ## directly, or perhaps set a score increment.
    $a_hash->{Score} = $action_num;

    if ( ! defined $action ) {
        $a_hash->{Code} = "sub {}";
        return XFD::Action::PerlCode->new( $a_hash ),
    }

    if ( $action_type eq "SCALAR" ) {
        $a_hash->{Code} = defined $action ? $action : "undef";
        $a_hash->{IsInlineCode} = 1;
        return XFD::Action::PerlCode->new( $a_hash ),
    }

    if ( !$action_type ) {
        my $handler_name = $action;
#        die "Unknown handler name '$handler_name', ",
#            keys %{$dispatcher->{Handlers}}
#                ? (
#                    "known handlers: ",
#                    join ", ", map "'$_'",
#                        keys %{$dispatcher->{Handlers}}
#                )
#                : "no handlers were set in constructor call",
#            "\n"
#            unless exists $dispatcher->{Handlers}->{$handler_name};

        $handler_name =~ s/([\\'])/\\$1/g;

        $a_hash->{Code} = "\$d->{Handlers}->{'$handler_name'}";

        return XFD::Action::EventForwarder->new( $a_hash );
    }

    if ( $action_type eq "CODE" ) {
        ## It's a code ref, arrange for it to be called
        ## directly.
        $a_hash->{CodeRef} = $action;
        $a_hash->{Code} =
            "\$d->{Actions}->[$action_num]->{CodeRef}->( \@_ )";
        return XFD::Action::PerlCode->new( $a_hash );
    }

    if (
        ## Crude way of eliminating most common ref types and deciding
        ## that the action is a blessed object.
        $action_type ne "HASH"
        && $action_type ne "REF"
        && $action_type ne "Regexp"
    ) {
        ## Must be a SAX handler, make up some action code to
        ## install it and arrange for it's removal.
        $a_hash->{Handler} = $action;
        $a_hash->{Code} = "\$d->{Actions}->[$action_num]->{Handler}";
        return XFD::Action::EventForwarder->new( $a_hash );
    }

    confess
        "action is a ", ref $action, " ref, not a SCALAR or ARRAY ref.";
}



###############################################################################
##
## Misc
##

## When an expression has been precursorized, it needs to run the
## relative path precursors wherever the expression was to be run,
## when enough precursors are satisfied, then the expression can
## run.  This happens in predicates and when a function call or
## math/logical operator (not union) is the main expression.
$f::indent = 0;  ## DEBUG ONLY
sub get_expr_code {  ## TODO: rename this
    my ( $is_predicate, $expr, $action_template, $action_ops, $path_remainder, $context ) = @_;
    ## if defined path_remainder, then it's a predicate expression
    ## otherwise, it's a top level expression.

    ## The action template is what needs to happen with the results of
    ## the expression.  It has a <EXPR> macro where the expression result
    ## must be evaluated and a <NEXT> tag that gets replaced with the
    ## actual operation (which may end up being the actual action, or it
    ## may code to satisfy a postponement).

    ## Localize Precursors.  If the expression requires precursors
    ## to be run, then converting it to immediate code will add them to
    ## Precursors.
#warn "## it's a predicate\n" if $is_predicate;
    local $context->{Precursors};

    my $expr_code = $expr->as_immed_code( $context );

    my $action_code = $is_predicate ? <<END_PREDICATE_TEMPLATE : $action_template;
if ( <EXPR> ) {
  emit_trace_SAX_message "EventPath: predicate postponement ", _po \$postponement, " MATCHED!" if is_tracing;
  <NEXT>}
END_PREDICATE_TEMPLATE

    _replace_NEXT $action_code, $expr_code, "<EXPR>";
    _replace_NEXT $action_code, $action_ops->as_incr_code( $context )
        if $action_ops;

    unless ( $context->{Precursors} ) {
        _replace_NEXT $action_code, $path_remainder->as_incr_code( $context )
            if $is_predicate;

        ## Return an immediate expression if no precursors were added.
        return $action_code
    }

    ## Some part of the expression was precursorized.  inline all
    ## relative precursors.
#{
#    warn "## precursorized\n";
#    my $c = $expr_code;
#    _indent $c for 0..$f::indent+1;
#    chomp $c;
#    warn "  expr_code:\n$c\n";
#    my $a = $action_code;
#    chomp $a;
#    _indent $a for 0..$f::indent+1;
#    warn "  action_code:\n$a\n";
#}

    ## Take any precursors and set them up to run right after the
    ## postponement is initialized.
    my @inline_precursor_codes;

    my %precursor_context = %$context;
    for my $precursor_number ( 0..$#{$context->{Precursors}} ) {
        if ( _is_rel_path $context->{Precursors}->[$precursor_number] ) {
            my $code = $context->{Precursors}->[$precursor_number]->as_incr_code(
                \%precursor_context
            );
            _indent $code if _indentomatic;
            push @inline_precursor_codes,
                "\n## relative precursor $precursor_number\n$code";
            undef $context->{Precursors}->[$precursor_number];
        }
    }

    my $postponement_init_code;

    if ( $is_predicate ) {
        ## It's a predicate
        my $leftmost = ! defined $context->{precursorize_action}
            ? " leftmost"
            : "";

        _indent $action_code if _indentomatic;
        _indent $action_code if _indentomatic;
        $postponement_init_code = $leftmost ? <<LEFTMOST_END : <<CODE_END;
\$postponement = [ undef ]; ## Leftmost predicate, no parent to report to
LEFTMOST_END
\$postponement = [ \$postponement ]; ## Refer to parent postponement
CODE_END
        ## TODO: Only add the push EndSubs code if there
        ## are <ACTION>s to perform
        ## TODO: Figure out what <ACTION> to perform if this is a
        ## predicate expression with no $path_remaining.  This can
        ## happen in a pattern like "a[b[c]]"; the "b[c]" predicate
        ## has no $path_remaining.  It *should* refer the results of
        ## its postponement (whether or not a <c> was found) back up
        ## to the parent postponement; probably by being in the
        ## context of the implicit boolean() wrapped around it by
        ## the a[] predicate.  See a commented out test in
        ## t/postponements.t for an example.
        $postponement_init_code .= <<CODE_END;
emit_trace_SAX_message "EventPath: creating postponement ", _po \$postponement, " for${leftmost} predicate in event ", _ev \$ctx if is_tracing;

emit_trace_SAX_message "EventPath: queuing check sub for postponement ", _po \$postponement if is_tracing;
push \@{\$ctx->{EndSubs}}, [
  sub {
    ## Called to see if the leftmost predicate matched
    my ( \$ctx, \$postponement ) = \@_;
    emit_trace_SAX_message "EventPath: checking${leftmost} predicate postponement ", _po \$postponement, " in event ", _ev \$ctx if is_tracing;
<ACTION>  },
  \$ctx,
  \$postponement
];
CODE_END

#    for my \$ctx ( \@{\$postponement->[_p_contexts]} ) {
#      \@{\$ctx->{Postponements}} = grep \$_ != \$postponement, \@{\$ctx->{Postponements}};
#      emit_trace_SAX_message "EventPath: ", \@{\$ctx->{Postponements}} . " postponements left in event ", _ev \$ctx, ": (", join( ", ", map _ev \$_, \@{\$ctx->{Postponements}} ), ")" if is_tracing;
#    }

        if ( $leftmost ) {
            ## this is the leftmost predicate expression
            die "ARGH!" if $context->{precursorized_action_codes};
            local $context->{precursorized_action_codes} = [];
            local $context->{precursorize_action} = <<CODE_END;
{
  my \$p = \$postponement->[_p_parent_postponement] || \$postponement;
  emit_trace_SAX_message "EventPath: adding context node ", _ev \$ctx, " to postponement ", _po \$p if is_tracing;
  \$ctx->{PostponementCount}++;
  push \@{\$p->[_p_contexts]}, \$ctx;
}
CODE_END

            local $context->{action_wrapper} = <<CODE_END;
if ( <EXPR> ) {
  emit_trace_SAX_message "EventPath: predicate postponement ", _po \$postponement, " MATCHED!" if is_tracing;
  while ( my \$ctx = shift \@{\$postponement->[_p_contexts]} ) {
    \$ctx->{PostponementCount}--;
    <ACTION>}
}
else {
  while ( my \$ctx = shift \@{\$postponement->[_p_contexts]} ) {
    \$ctx->{PostponementCount}--;
  }
}
CODE_END

            _indent $context->{action_wrapper} if _indentomatic;
            _indent $context->{action_wrapper} if _indentomatic;
            _replace_NEXT $context->{action_wrapper}, $expr_code, "<EXPR>";

            $action_code = "## NO ACTION LEFT\n";

local $f::indent = $f::indent + 1;
            if ( $path_remainder ) {
                my $code = $path_remainder->as_incr_code( $context );
                push @inline_precursor_codes,
                    "\n## remainder of location path\n$code";
            }

            _replace_NEXT
                $postponement_init_code,
                join( "", @{$context->{precursorized_action_codes}} ),
                "<ACTION>";
        }
        else {
#warn "    ## non-leftmost predicate\n";
            ## It's a non-leftmost predicate.

local $f::indent = $f::indent + 1;
            if ( $path_remainder ) {
                my $code = $path_remainder->as_incr_code( $context );
                _indent $code if _indentomatic;
                push @inline_precursor_codes,
                    "\n## remainder of location path\n$code";
            }

##            $postponement_init_code = <<CODE_END;
##my \$parent_postponement = \$postponement;
##\$postponement = [ \$parent_postponement ];
##emit_trace_SAX_message "EventPath: creating postponement ", _po \$postponement, " for predicate (non-leftmost) in event ", _ev \$ctx if is_tracing;
##CODE_END
##
            _replace_NEXT $action_code, <<CODE_END;
if ( \$postponement->[_p_contexts] ) {
  my \$parent_postponement = \$postponement->[_p_parent_postponement];
  emit_trace_SAX_message "EventPath: moving context nodes from postponement ", _po \$postponement, " to parent postponement ", _po \$parent_postponement if is_tracing;
  push
    \@{\$parent_postponement->[_p_contexts]},
    splice \@{\$postponement->[_p_contexts]};
}
else {
  emit_trace_SAX_message "EventPath: but no context nodes in postponement ", _po \$postponement if is_tracing;
}
CODE_END

##            _indent $action_code if _indentomatic;
##            _indent $action_code if _indentomatic;
##            $action_code = <<CODE_END;
##push \@{\$ctx->{EndSubs}}, [
##  sub {
##    ## Called to see if a non-leftmost predicate matched
##    my ( \$ctx, \$parent_postponement, \$postponement ) = \@_;
##    emit_trace_SAX_message "EventPath: checking postponement ", _po \$postponement, " for predicate (non-leftmost)" if is_tracing;
##warn \$postponement->[_p_first_precursor+0];
##    for my \$ctx ( \@{\$postponement->[_p_contexts]} ) {
##      \@{\$ctx->{Postponements}} = grep \$_ != \$postponement, \@{\$ctx->{Postponements}};
##      emit_trace_SAX_message \@{\$ctx->{Postponements}} . " postponements left in event ", _ev \$ctx, ": (", join( ", ", map _ev \$_, \@{\$ctx->{Postponements}} ), ")" if is_tracing;
##    }
##$action_code  },
##  \$ctx,
##  \$parent_postponement,
##  \$postponement
##];
##CODE_END
            _replace_NEXT
                $postponement_init_code,
                join( "", @{$context->{precursorized_action_codes}} ),
                "<ACTION>";
        }
    }
    else {
#warn "  ## it's an expression\n";
        ## It's an expression, not a predicate
        _indent $action_code if _indentomatic;
        _indent $action_code if _indentomatic;
        $postponement_init_code = <<CODE_END;
\$postponement = [ \$postponement ];  ## Refer to parent postponement, if present
emit_trace_SAX_message "EventPath: creating expression postponement ", _po \$postponement, " in event ", _ev \$ctx if is_tracing;
\$ctx->{PostponementCount}++;
push \@{\$ctx->{EndSubs}}, [
  sub {
    ## Called to calculate the postponed expression.
    my ( \$ctx, \$postponement ) = \@_;
    emit_trace_SAX_message "EventPath: checking expression postponement ", _po \$postponement, " in event ", _ev \$ctx if is_tracing;
    \$ctx->{PostponementCount}--;
    emit_trace_SAX_message \$ctx->{PostponementCount} . " postponements left in event ", _ev \$ctx if is_tracing;
$action_code  },
  \$ctx,
  \$postponement
];
CODE_END
        $action_code = "";
    }

#    my $code = $self->insert_next_in_to_template( <<CODE_END );
## TODO: figure a way for the absolute precursors to fire this expression.
#{
#    my $p = $postponement_init_code;
#    _indent $p for 0..$f::indent+1;
#    chomp $p;
#    warn "  postponement_init_code:\n$p\n";
#
#    for ( @inline_precursor_codes ) {
#        my $a = $_;
#        chomp $a;
#        _indent $a for 0..$f::indent+1;
#        warn "  precursor_code:\n$a\n";
#    }
#
#    my $a = $action_code;
#    chomp $a;
#    _indent $a for 0..$f::indent+1;
#    warn "  action_code:\n$a\n";
#}


    local $" = "";
    my $code = <<CODE_END;
$postponement_init_code@inline_precursor_codes
$action_code
CODE_END

    return $code;
}

###############################################################################
##
## Functions
##

## Boolean functions return 0 or 1, it's up to expr_eval (or any
## other code which passes these in or out to perl code) to convert
## these to true() or false().  Passing these in/out of this subsystem
## is far rarer than using them within it. Using 1 or 0 lets
## the optimization code and the generated use numeric or boolean
## Perl ops.

## When compiled, expressions and function calls are turned in to
## Perl code right in the grammar, with a vew exceptions like
## string( node-set ).

## The parser calls this
sub function {
    my ( $name, $parms ) = @_;
    
    no strict 'refs';

    ## prevent ppl from spelling then "foo_bar"
    my $real_name = $name;
    my $had_underscores = $real_name =~ s/_/*NO-UNDERSCORES-PLEASE*/g;
    $real_name =~ s/-/_/g;

    unless ( "XFD::Function::$real_name"->can( "new" ) ) {
        if ( $had_underscores ) {
            if ( $had_underscores ) {
                $real_name = $name;
                $real_name =~ s/-/_/g;
                if ( defined &{"XFD::Function::$real_name"} ) {
                    die
                "XPath function mispelled, use '-' instead of '_' in '$name'\n";
                }
            }
        }
        die "unknown XPath function '$name'\n";
    }

    return "XFD::Function::$real_name"->new( @$parms );
}


## Many XPath functions use a node set of the context node when
## no args are provided.
sub _default_to_context {
    my $args = shift;
    return $args if @$args;

    my $s = XFD::Axis::self->new;
    my $n = XFD::EventType::node->new;
    $s->set_next( $n );
    return [ $s ];
}


####################
@XFD::Function::ISA = qw( XFD::Op );


   @XFD::BooleanFunction::ISA          = qw( XFD::Function );
sub XFD::BooleanFunction::result_type  { "boolean" }
sub XFD::BooleanFunction::parm_type    { "boolean" }
   @XFD::NodesetFunction::ISA          = qw( XFD::Function );
sub XFD::NodesetFunction::result_type  { "string" }
sub XFD::NodesetFunction::parm_type    { "nodeset" }
   @XFD::NumericFunction::ISA          = qw( XFD::Function );
sub XFD::NumericFunction::result_type  { "number"  }
sub XFD::NumericFunction::parm_type    { "number"  }
   @XFD::StringFunction::ISA           = qw( XFD::Function );
sub XFD::StringFunction::result_type   { "string"  }
sub XFD::StringFunction::parm_type     { "string"  }

sub XFD::Function::op_type { shift->XFD::Op::op_type . "()" }

##
## NOTE: munge_parms is where all the precursor detection magic occurs.
## A precursor is detected when a parameter to a function (or operator)
## queues up one or more precursors when converted to immediate code.
## By definition, a precursor can't be executed immediately.
##
sub XFD::Function::munge_parms {
    ## police parms and convert to appropriate type as needed.
    my $self = shift;
    my ( $min, $max, $context ) = @_;

    ( my $sub_name = ref $self ) =~ s/.*://;

    die "$min > $max!!\n" if defined $max && $min > $max;

    my $msg;
    my $cnt = @$self;
    if ( defined $max && $max == $min ) {
        $msg = "takes $min parameters" unless $cnt == $min;
    }
    elsif ( $cnt < $min ) {
        $msg = "takes at least $min parameters";
    }
    elsif ( defined $max && $cnt > $max ) {
        $msg = "takes at most $max parameters";
    }

    my @errors;
    push @errors, "$sub_name() $msg, got $cnt\n"
        if defined $msg;
    my $num = 0;

    my @parm_codes;

    for my $parm ( @$self ) {
        my $required_type = $self->parm_type( $num );
        ++$num;

        my $type = $parm->result_type;

        if ( $type ne $required_type
            || ( $type eq "nodeset" && $required_type eq "nodeset" )
        ) {
            my $cvt = "XFD::${type}2$required_type";
            if ( $cvt->can( "new" ) ) {
                $parm = $cvt->new( $parm );
            }
            else {
                push @errors,
                    "Can't convert ",
                    $type,
                    " to ",
                    $required_type,
                    " in ",
                    $sub_name,
                    "() parameter ",
                    $num,
                    "\n"
            }
        }

        push @parm_codes, $parm->as_immed_code( $context );
    }

    die @errors if @errors;

    return @parm_codes;
}


sub XFD::Function::build_expr {
    my $self = shift;
    my ( undef, undef, $context ) = @_;

    my $code_sub = pop;
    my $code = $code_sub->( $self->munge_parms( @_ ) );

    $code = _eval_at_compile_time $self->result_type, $code, $context
        if $self->is_constant;
        
    return $code;
}

###############################################################################
##
## Type Converters
##
@XFD::Converter::ISA = qw( XFD::Function );

sub XFD::Converter::result_type { ( my $foo = ref shift ) =~ s/.*2//; $foo }

sub XFD::Converter::as_immed_code {
    my $self = shift;

    my $code = $self->immed_code_template( @_ );

    my $parm = $self->[0];
    _replace_NEXT $code, $parm->as_immed_code( @_ ) if defined $parm;

    return $code;
}


## NaN is not handled properly.

   @XFD::boolean2number::ISA = qw( XFD::Converter );
sub XFD::boolean2number::immed_code_template {
    ## Internally, booleans are numeric, force them to 0 or 1.
    return "<NEXT> ? 1 : 0";
}

   @XFD::boolean2string::ISA = qw( XFD::Converter );
sub XFD::boolean2string::immed_code_template {
    ## Internally, booleans are numeric
    return "( <NEXT> ? 'true' : 'false' )";
}

## "int" is used internally to get things rounded right.
   @XFD::number2int::ISA = qw( XFD::Converter );
sub XFD::number2int::result_type { "number" }
sub XFD::number2int::immed_code_template {
    require POSIX;
    return "POSIX::floor( <NEXT> + 0.5 )";
}

   @XFD::number2string::ISA = qw( XFD::Converter );
sub XFD::number2string::immed_code_template  {
    ## The 0+ is to force the scalar in to a numeric format, so to
    ## trim leading zeros.  This will have the side effect that any
    ## numbers that don't "fit" in to the local machine's notion of
    ## a floating point Perl scaler will be munged to the closest
    ## approximation, but hey...
    return
        "do { my \$n = <NEXT>; ( \$n ne 'NaN' ? 0+\$n : \$n ) }";
}

   @XFD::number2boolean::ISA = qw( XFD::Converter );
sub XFD::number2boolean::immed_code_template {
    return
       "do { my \$n = <NEXT>; ( \$n ne 'NaN' && \$n ) ? 1 : 0 }";
}

   @XFD::string2boolean::ISA = qw( XFD::Converter );
sub XFD::string2boolean::immed_code_template {
    return "( length <NEXT> ? 1 : 0 )";
}

   @XFD::string2number::ISA = qw( XFD::Converter );
sub XFD::string2number::immed_code_template {
    ## The "0+" forces it to a number, hopefully it was a number
    ## the local machine's perl can represent accurately.
    return qq{do { my \$s = <NEXT>; _looks_numeric \$s ? 0+\$s : die "can't convert '\$s' to a number in XPath expression"}};
}

## the any2..._rt are used at runtime when we have no idea at compile time
## about type.  So far, this only happens with variable refs.  Unlike the
## other converters, these are called at runtime.
sub _any2boolean_rt {
    my $any_value = shift;

    my $type = ref $any_value;
    $type =~ s/.*://;
    $type =~ s/ .*//;

    my $value = $$any_value;

    return $value                   if $type eq "boolean";
    return $value ? 1 : 0           if $type eq "number";
    return length( $value ) ? 1 : 0 if $type eq "string";

    die "Can't convert '$type' to boolean\n";
}

   @XFD::any2boolean::ISA = qw( XFD::Converter );
sub XFD::any2boolean::immed_code_template { "_any2boolean_rt( <NEXT> )" }
##########
sub _any2string_rt {
    my $any_value = shift;

    my $type = ref $any_value;
    $type =~ s/.*://;
    $type =~ s/ .*//;

    my $value = $$any_value;

    return $any_value if $type eq "string";
    return 0+$any_value if $type eq "number";
    if ( $type eq "boolean" ) {
        return ref $value
            ? UNIVERSAL::isa( "XFD::true" )
                ? "true"
                : "false"
            : $value ? "true" : "false";
    }

    die "Can't convert '$type' to string\n";
}

   @XFD::any2string::ISA = qw( XFD::Converter );
sub XFD::any2string::immed_code_template { "_any2string_rt( <NEXT> )" }
##########
sub _any2number_rt {
    my $any_value = shift;

    my $type = ref $any_value;
    $type =~ s/.*://;
    $type =~ s/ .*//;

    my $value = $$any_value;

    return 0+$any_value if $type eq "number";

    if ( $type eq "boolean" ) {
        return ref $value
            ? UNIVERSAL::isa( "XFD::true" ) ? 1 : 0
            : $value ? 1 : 0;
    }

    if ( $type eq "string" ) {
        return 0+$value if _looks_numeric $value;
        return "NaN";
    }

    die "Can't convert '$type' to number\n";
}

   @XFD::any2number::ISA = qw( XFD::Converter );
sub XFD::any2number::immed_code_template { "_any2number_rt( <NEXT> )" }
########################################
##
## nodeset2foo converters
##

   @XFD::NodesetConverter::ISA = qw( XFD::Converter );
sub XFD::NodesetConverter::result_type { ( ( ref shift ) =~ m/2(.*)/ )[0] }
sub XFD::NodesetConverter::incr_code_template {
    Carp::confess( ref shift ) . " cannot generate incremental code";
}

sub XFD::NodesetConverter::as_immed_code {
    my $self = shift;
    my ( $context ) = @_;

    my $expr_code = eval {
        $self->[0]->XFD::Converter::as_immed_code( $context );
    };

    if ( defined $expr_code ) {
        my $code = $self->immed_code_template( @_ );
        _replace_NEXT $code, $expr_code;
        return $code;
    }
    die $@ unless $@ eq "precursorize THIS\n";

    my ( $postponer_class )
        = "XFD::" . ucfirst( $self->result_type ) . "Postponer";

    my $precursor_number = $#{$context->{Precursors}} + 1;

    my $postponer = $postponer_class->new( $precursor_number );

    $postponer->set_next( $self->[0] );

    push @{$context->{Precursors}}, $postponer;

    return $self->precursor_fetching_code( $precursor_number );
}


##
## When a NodesetConverter notices that it's nodeset expression
## needs to be precursorized, it places one of these at the
## head of the location path to manage precursorization.
## This allows a boolean conversion to operate differently than
## a string/numeric one, for instance.
##
## TODO: Allow these to signal the enclosing path test to not
## re-curry itself if the precursor has been satisfied.
sub _np_precursor_number() { 0 }
   @XFD::NodesetPostponer::ISA = qw( XFD::PathTest );
sub XFD::NodesetPostponer::as_incr_code {
    my $self = shift;
    my $context = shift;
    local $context->{ActionCode} = $self->postponement_setting_code;
    my $code = $self->[_next]->as_incr_code( $context );
    return $code;
}
sub XFD::NodesetPostponer::postponement_setting_code {
    ## This is overridden by number, string, boolean postponers
    my $self = shift;
    my $precursor_number = $self->[_np_precursor_number];
    return <<CODE_END;
emit_trace_SAX_message "EventPath: Setting postponement for precursor $precursor_number" if is_tracing;
\$postponement->[_p_first_precursor+$precursor_number] = \$ctx; ## Nodeset postponer
CODE_END
}


##########
@XFD::nodeset2string::ISA = qw( XFD::NodesetConverter );
sub XFD::nodeset2string::immed_code_template {
    ## This is used in cases where the location path can be
    ## evaluated immediately.
    return <<CODE_END;
do { ## nodeset2string
  my \$ctx = (
    <NEXT>
  )[0];
  exists \$ctx->{Node}->{Value}
    ? \$ctx->{Node}->{Value}
    : "";
} # nodeset2string
CODE_END
}


sub XFD::nodeset2string::precursor_fetching_code {
    my $self = shift;
    my ( $precursor_number ) = @_;

    return qq{(
  defined \$postponement->[_p_first_precursor+$precursor_number]
        ? \$postponement->[_p_first_precursor+$precursor_number]
        : ""
)};
}


   @XFD::StringPostponer::ISA = qw( XFD::NodesetPostponer );
sub XFD::StringPostponer::postponement_setting_code {
    my $self = shift;
    my $precursor_number = $self->[_np_precursor_number];
    return <<CODE_END;
unless ( defined \$postponement->[_p_first_precursor+$precursor_number] ) { ## nodeset2string
  if ( \$ctx->{EventType} eq "start_document"
    || \$ctx->{EventType} eq "start_element"
  ) {
    emit_trace_SAX_message "EventPath: enabling text collection for precursor $precursor_number (postponement ", _po \$postponement, ")" if is_tracing;
    nodeset2string_start( \$postponement, $precursor_number );
    ## If this is one branch of a union, we need to define this
    ## precursor so the other branch of the union won't also
    ## start collecting text.
    \$postponement->[_p_first_precursor+$precursor_number] = "";
  }
  else {
    emit_trace_SAX_message "EventPath: setting precursor $precursor_number to string" if is_tracing;
    my \$type = \$ctx->{EventType};
    \$postponement->[_p_first_precursor+$precursor_number] = (
        \$type eq "attribute"              ? \$ctx->{Node}->{Value}
                                          : \$ctx->{Node}->{Data}
    );
    \$postponement->[_p_first_precursor+$precursor_number] = ""
      unless defined \$postponement->[_p_first_precursor+$precursor_number];
  }
} # nodeset2string
CODE_END
}

##########
@XFD::nodeset2hash::ISA = qw( XFD::NodesetConverter );
sub XFD::nodeset2hash::immed_code_template {
    ## This is used in cases where the location path can be
    ## evaluated immediately.
    die "nodeset2hash::immed_code_template not implemented yet\n";
    return <<CODE_END;
do { ## nodeset2hash
  my \$ctx = (
    <NEXT>
  )[0];
  exists \$ctx->{Node}->{Value}
    ? \$ctx->{Node}->{Value}
    : "";
} # nodeset2hash
CODE_END
}


sub XFD::nodeset2hash::precursor_fetching_code {
    my $self = shift;
    my ( $precursor_number ) = @_;

    return qq{\$postponement->[_p_first_precursor+$precursor_number]->end_document};
}

   @XFD::HashPostponer::ISA = qw( XFD::NodesetPostponer );
sub XFD::HashPostponer::postponement_setting_code {
    my $self = shift;
    my $precursor_number = $self->[_np_precursor_number];
    ## TODO: check to see if we really need this if EventType eq ... stuff
    ## it should be known at compile time, perhaps even just by dint of us
    ## setting the acceptable events for this opcode to be queued for.
    return <<CODE_END;
unless ( defined \$postponement->[_p_first_precursor+$precursor_number] ) { ## nodeset2hash
  if ( \$ctx->{EventType} eq "start_document"
    || \$ctx->{EventType} eq "start_element"
  ) {
    ## Note that, if this is one branch of a union, defining this
    ## precursor prevents the other branch of the union from also
    ## building a hash over top of this one.
    ## TODO: allow the caller to specify this class name
    require XML::Filter::Dispatcher::AsHashHandler;
    \$XFD::AsHashHandlers[0] ||= XML::Filter::Dispatcher::AsHashHandler->new;
    my \$h = \$postponement->[_p_first_precursor+$precursor_number] =
        shift \@XFD::AsHashHandlers;

    \$h->set_namespaces( \$d->{Namespaces} ? %{ \$d->{Namespaces} } : () );

    emit_trace_SAX_message "EventPath: precursor $precursor_number is handled by \$h" if is_tracing;

    \$h->start_document( {} );  ## superfluous in the current version, but just in case...

    my \$end_element = \$h->can( "end_element" );
    ## nodeset2hash_start() will queue up the matching end_element
    \$h->start_element( \$ctx->{Node} )
      if \$ctx->{EventType} eq "start_element";

    nodeset2hash_start(
      \$h,
      \$h->can( "start_element" ),
      \$h->can( "characters"    ),
      \$end_element,
    );

    push \@{\$ctx->{EndSubs}}, [
      sub {
        unshift \@XFD::AsHashHandlers, shift;
      },
      \$h,
    ];
  }
  else {
    ## TODO: do this at compile time.
    die "EventPath function hash() requires a start_element or start_document\n";
  }
} # nodeset2hash
CODE_END
}

##########
@XFD::nodeset2struct::ISA = qw( XFD::NodesetConverter );
sub XFD::nodeset2struct::immed_code_template {
    ## This is used in cases where the location path can be
    ## evaluated immediately.
    die "nodeset2struct::immed_code_template not implemented yet\n";
    return <<CODE_END;
do { ## nodeset2struct
  my \$ctx = (
    <NEXT>
  )[0];
  exists \$ctx->{Node}->{Value}
    ? \$ctx->{Node}->{Value}
    : "";
} # nodeset2struct
CODE_END
}


sub XFD::nodeset2struct::precursor_fetching_code {
    my $self = shift;
    my ( $precursor_number ) = @_;

    return qq{\$postponement->[_p_first_precursor+$precursor_number]->end_document};
}

   @XFD::StructPostponer::ISA = qw( XFD::NodesetPostponer );
sub XFD::StructPostponer::postponement_setting_code {
    my $self = shift;
    my $precursor_number = $self->[_np_precursor_number];
    ## TODO: check to see if we really need this if EventType eq ... stuff
    ## it should be known at compile time, perhaps even just by dint of us
    ## setting the acceptable events for this opcode to be queued for.
    return <<CODE_END;
unless ( defined \$postponement->[_p_first_precursor+$precursor_number] ) { ## nodeset2struct
  if ( \$ctx->{EventType} eq "start_document"
    || \$ctx->{EventType} eq "start_element"
  ) {
    ## Note that, if this is one branch of a union, defining this
    ## precursor prevents the other branch of the union from also
    ## building a struct over top of this one.
    ## TODO: allow the caller to specify this class name
    require XML::Filter::Dispatcher::AsStructHandler;
    \$XFD::AsStructHandlers[0] ||= XML::Filter::Dispatcher::AsStructHandler->new;
    my \$h = \$postponement->[_p_first_precursor+$precursor_number] =
        shift \@XFD::AsStructHandlers;

    \$h->set_namespaces( \$d->{Namespaces} ? %{ \$d->{Namespaces} } : () );

    emit_trace_SAX_message "EventPath: precursor $precursor_number is handled by \$h" if is_tracing;

    \$h->start_document( {} );  ## superfluous in the current version, but just in case...

    my \$end_element = \$h->can( "end_element" );
    ## nodeset2struct_start() will queue up the matching end_element
    \$h->start_element( \$ctx->{Node} )
      if \$ctx->{EventType} eq "start_element";

    nodeset2struct_start(
      \$h,
      \$h->can( "start_element" ),
      \$h->can( "characters"    ),
      \$end_element,
    );

    push \@{\$ctx->{EndSubs}}, [
      sub {
        unshift \@XFD::AsStructHandlers, shift;
      },
      \$h,
    ];
  }
  else {
    ## TODO: do this at compile time.
    die "EventPath function struct() requires a start_element or start_document\n";
  }
} # nodeset2struct
CODE_END
}

##########
##########
@XFD::nodeset2number::ISA = qw( XFD::NodesetConverter );

sub XFD::nodeset2number::immed_code_template {
    ## This is used in cases where the location path can be
    ## evaluated immediately.
    return <<CODE_END;
do { ## nodeset2number
  my \$ctx = (
    <NEXT>
  )[0];
  ( exists \$ctx->{Node}->{Value} && _looks_numeric \$ctx->{Node}->{Value} )
    ? 0 + \$ctx->{Node}->{Value}
    : "NaN";
} # nodeset2number
CODE_END
}


sub XFD::nodeset2number::precursor_fetching_code {
    my $self = shift;
    my ( $precursor_number ) = @_;

    return qq[do {
  my \$string = \$postponement->[_p_first_precursor+$precursor_number];
  ( defined \$string && _looks_numeric( \$string ) ) ? 0 + \$string
                                                  : "NaN"
}];
}


## Collect text *just* like a string.
@XFD::NumberPostponer::ISA = qw( XFD::StringPostponer );

##########
   @XFD::nodeset2boolean::ISA = qw( XFD::NodesetConverter );

sub XFD::nodeset2boolean::immed_code_template {
    return <<CODE_END;
(
  scalar( ## nodeset2boolean
    <NEXT>
  ) ? 1 : 0
) # nodeset2boolean
CODE_END
}

sub XFD::nodeset2boolean::precursor_fetching_code {
    my $self = shift;
    my ( $precursor_number ) = @_;

    return
        "( \$postponement->[_p_first_precursor+$precursor_number] || 0 )";
}


sub XFD::nodeset2boolean::default_value_code { '""' };

   @XFD::BooleanPostponer::ISA = qw( XFD::NodesetPostponer );
sub XFD::BooleanPostponer::postponement_setting_code {
    my $self = shift;
    my $precursor_number = $self->[_np_precursor_number];
    return <<CODE_END;
\$postponement->[_p_first_precursor+$precursor_number] = 1; ## nodeset2boolean: if we got here, the nodeset is non-empty.
CODE_END
}

##########
   @XFD::nodeset2nodeset::ISA = qw( XFD::NodesetConverter );
sub XFD::nodeset2nodeset::immed_code_template {
    return "<NEXT>";
}


sub XFD::nodeset2nodeset::precursor_fetching_code {
    my $self = shift;
    my ( $precursor_number ) = @_;

    return
        "( \$postponement->[_p_first_precursor+$precursor_number] || \$ctx )";
}

###############################################################################
##
## User Visible Functions
##
## These (and only these) must all be in the XFD::Function::* namespaces,
## so function() can find them.  They derive from a subclass that indicates
## their return types so munge_parms() can figure out what it's parameters
## return.
##

## The first "$_[0]" in this:
##    shift->build_expr( 1, 1, $_[0], sub { $_[0] } );
## is $context.

##########

   @XFD::Function::boolean::ISA = qw( XFD::BooleanFunction );
sub XFD::Function::boolean::as_immed_code {
    shift->build_expr( 1, 1, $_[0], sub { $_[0] } );
}
##########
   @XFD::Function::ceiling::ISA = qw( XFD::NumericFunction );
sub XFD::Function::ceiling::as_immed_code {
    require POSIX;
    shift->build_expr( 1, 1, $_[0], sub {"POSIX::ceil( $_[0] )" } );
}
##########
   @XFD::Function::concat::ISA = qw( XFD::StringFunction );
sub XFD::Function::concat::as_immed_code {
    shift->build_expr( 2, undef, $_[0], sub {
        "join( '', " . join( ", ", @_ ) . " )";
    } );
}
##########
   @XFD::Function::contains::ISA = qw( XFD::BooleanFunction );
sub XFD::Function::contains::parm_type { "string" }
sub XFD::Function::contains::as_immed_code {
    shift->build_expr( 2, 2, $_[0], sub {
        "0 <= index( " . join( ", ", @_ ) . " )";
    } );
}
##########
   @XFD::Function::false::ISA = qw( XFD::BooleanFunction );
sub XFD::Function::false::as_immed_code {
    shift->build_expr( 0, 0, $_[0], sub { "0" } );
}
##########
   @XFD::Function::floor::ISA = qw( XFD::NumericFunction );
sub XFD::Function::floor::as_immed_code {
    require POSIX;
    shift->build_expr( 1, 1, $_[0], sub {"POSIX::floor( $_[0] )"} );
}
##########
   @XFD::Function::hash::ISA = qw( XFD::NodesetFunction );
sub XFD::Function::hash::result_type { "hash" }
sub XFD::Function::hash::parm_type   { "hash" }
sub XFD::Function::hash::new {
    my $self = shift->XFD::NodesetFunction::new( @_ );
    push @$self, XFD::self_node->new unless @$self;
    return $self;
}

sub XFD::Function::hash::as_immed_code {
    shift->build_expr( 1, 1, $_[0], sub { $_[0] } );
}
##########
   @XFD::Function::normalize_space::ISA = qw( XFD::StringFunction );
sub XFD::Function::normalize_space::new {
    my $self = shift->XFD::StringFunction::new( @_ );
    push @$self, XFD::self_node->new unless @$self;
    return $self;
}

sub XFD::Function::normalize_space::as_immed_code {
    ## We don't do the argless version because we can't for all nodes, since
    ## that would require keeping entire subtrees around.  We might be
    ## able to do it for attributes and leaf elements, throwing an error
    ## at runtime if the node is not a leaf node.
    shift->build_expr( 1, 1, $_[0], sub {
        "do { my \$s = $_[0]; \$s =~ s/^[ \\t\\r\\n]+//; \$s =~ s/[ \\t\\r\\n]+(?!\\n)\\Z//; \$s =~ s/[ \\t\\r\\n]+/ /g; \$s }";
    } );

}
##########
   @XFD::Function::not::ISA = qw( XFD::BooleanFunction );
sub XFD::Function::not::as_immed_code {
    shift->build_expr( 1, 1, $_[0], sub { "! $_[0]" } );
}
##########
   @XFD::Function::number::ISA = qw( XFD::NumericFunction );
sub XFD::Function::number::new {
    my $self = shift->XFD::NumericFunction::new( @_ );
    push @$self, XFD::self_node->new unless @$self;
    return $self;
}
sub XFD::Function::number::as_immed_code {
    shift->build_expr( 1, 1, $_[0], sub { $_[0] } );
}
##########
   @XFD::Function::local_name::ISA = qw( XFD::NodesetFunction );
sub XFD::Function::local_name::new {
    my $self = shift->XFD::NodesetFunction::new( @_ );
    push @$self, XFD::self_node->new unless @$self;
    return $self;
}
sub XFD::Function::local_name::as_immed_code {
    shift->build_expr( 1, 1, $_[0], sub {
        "( exists( $_[0]\->{Node}->{LocalName} ) && $_[0]\->{Node}->{LocalName} ) || \"\"";
    } );
}
##########
   @XFD::Function::name::ISA = qw( XFD::NodesetFunction );
sub XFD::Function::name::new {
    my $self = shift->XFD::NodesetFunction::new( @_ );
    push @$self, XFD::self_node->new unless @$self;
    return $self;
}
sub XFD::Function::name::as_immed_code {
    shift->build_expr( 1, 1, $_[0], sub {
        "( exists( $_[0]\->{Node}->{Name} ) && $_[0]\->{Node}->{Name} ) || \"\"";
    } );
}
##########
   @XFD::Function::namespace_uri::ISA = qw( XFD::NodesetFunction );
sub XFD::Function::namespace_uri::new {
    my $self = shift->XFD::NodesetFunction::new( @_ );
    push @$self, XFD::self_node->new unless @$self;
    return $self;
}
sub XFD::Function::namespace_uri::as_immed_code {
    shift->build_expr( 1, 1, $_[0], sub {
        "( defined( $_[0]\->{Node}->{NamespaceURI} ) ? $_[0]\->{Node}->{NamespaceURI} : \"\" )";
    } );
}
##########
   @XFD::Function::round::ISA = qw( XFD::NumericFunction );
sub XFD::Function::round::as_immed_code {
    require POSIX;
    ## Expressly ignoring the -0 conditions in the spec.
    shift->build_expr( 1, 1, $_[0], sub {"POSIX::floor( $_[0] + 0.5 )"} );
}
##########
   @XFD::Function::starts_with::ISA = qw( XFD::BooleanFunction );
sub XFD::Function::starts_with::parm_type { "string" }
sub XFD::Function::starts_with::as_immed_code {
    shift->build_expr( 2, 2, $_[0], sub {
        "0 == index( " . join( ", ", @_ ) . " )";
    } );
}
##########
   @XFD::Function::string::ISA = qw( XFD::StringFunction );
sub XFD::Function::string::new {
    my $self = shift->XFD::StringFunction::new( @_ );
    push @$self, XFD::self_node->new unless @$self;
    return $self;
}

sub XFD::Function::string::as_immed_code {
    shift->build_expr( 1, 1, $_[0], sub { $_[0] } );
}
##########
   @XFD::Function::string_length::ISA = qw( XFD::NumericFunction );
sub XFD::Function::string_length::new {
    my $self = shift->XFD::NumericFunction::new( @_ );
    push @$self, XFD::self_node->new unless @$self;
    return $self;
}

sub XFD::Function::string_length::parm_type { "string" }
sub XFD::Function::string_length::as_immed_code {
    ## We don't do string-length() because we can't for all nodes, since
    ## that would require keeping entire subtrees around.  We might be
    ## able to do it for attributes and leaf elements, throwing an error
    ## at runtime if the node is not a leaf node.
    shift->build_expr( 1, 1, $_[0], sub { "length( $_[0] )" } );
}
##########
   @XFD::Function::struct::ISA = qw( XFD::NodesetFunction );
sub XFD::Function::struct::result_type { "struct" }
sub XFD::Function::struct::parm_type   { "struct" }
sub XFD::Function::struct::new {
    my $self = shift->XFD::NodesetFunction::new( @_ );
    push @$self, XFD::self_node->new unless @$self;
    return $self;
}

sub XFD::Function::struct::as_immed_code {
    shift->build_expr( 1, 1, $_[0], sub { $_[0] } );
}
##########
   @XFD::Function::substring::ISA = qw( XFD::StringFunction );
sub XFD::Function::substring::parm_type {
    my $self = shift;
    return shift == 0 ? "string" : "int";
}

sub XFD::Function::substring::as_immed_code {
    my $self = shift;
    my ( $context ) = @_;

    my @args = $self->munge_parms( 2, 3, $context );

    my @is_constant = map $_->is_constant, @$self;

    my $code;
    if ( @args == 2 ) {
        my $pos_code =
            "do { my \$pos = $args[1] - 1; \$pos = 0 if \$pos < 0; \$pos}";

        $pos_code = _eval_at_compile_time "number", $pos_code, $context
            if $is_constant[1];
        $code = "substr( $args[0], $pos_code )";
    }
    else {
        ## must be 3 arg form.
        my $pos_len_code =
            "do { my ( \$pos, \$len ) = ( $args[1] - 1, $args[2] ); my \$end = \$pos + \$len; \$pos = 0 if \$pos < 0; \$len = \$end - \$pos ; \$len = 0 if \$len < 0; ( \$pos, \$len ) }";

        ## Not bothering to optimize the substring( <whatever>, <const>, <var> )
        ## situation, only substring( <whatever>, <const>, <const> )

        if ( $is_constant[1] && $is_constant[2] ) {
            my ( $pos, $len ) = eval $pos_len_code
                or die "$! executing XPath (number, number) $pos_len_code at compile time\n";
            $code = "substr( $args[0], $pos, $len )" ;
        }
        else {
            $code = "substr( $args[0], $pos_len_code )" ;
        }
    }

    $code = _eval_at_compile_time "string", $code, $context
        if $self->is_constant;

    return $code;
}
##########
   @XFD::Function::substring_after::ISA = qw( XFD::StringFunction );
sub XFD::Function::substring_after::as_immed_code {
    shift->build_expr( 2, 2, $_[0], sub {
        "do { my ( \$s, \$ss ) = ( $_[0], $_[1] ); my \$pos = index \$s, \$ss; \$pos >= 0 ? substr \$s, \$pos + length \$ss : ''  }";
    } );
}
##########
   @XFD::Function::substring_before::ISA = qw( XFD::StringFunction );
sub XFD::Function::substring_before::as_immed_code {
    shift->build_expr( 2, 2, $_[0], sub {
        "do { my \$s = $_[0]; my \$pos = index \$s, $_[1]; \$pos >= 0 ? substr \$s, 0, \$pos : ''  }";
    } );
}
##########
   @XFD::Function::translate::ISA = qw( XFD::StringFunction );
sub XFD::Function::translate::as_immed_code {
    ## We don't implement the argless version because we can't for all nodes,
    ## since that would require keeping entire subtrees around.  We might be
    ## able to do it for attributes and leaf elements, throwing an error
    ## at runtime if the node is not a leaf node.

    ## TODO: verify that quotemeta is really enough and is correct, here.

    ## We don't handle the case where only one of $from and $to is constant,
    ## should be rare (hell, just seeing translate() anywhere should be rare).
    ## This was not true for substring() above, which I suspect will be
    ## called a bit more than translate().
    shift->build_expr( 3, 3, $_[0], sub {
        "do { my ( \$s, \$f, \$t ) = ( $_[0], quotemeta $_[1], quotemeta $_[2] ); eval qq{\\\$s =~ tr/\$f/\$t/d}; \$s }";
    } );
}
##########
   @XFD::Function::true::ISA = qw( XFD::BooleanFunction );
sub XFD::Function::true::as_immed_code {
    shift->build_expr( 0, 0, $_[0], sub { "1" } );
}

###############################################################################
##
## Variable references
##
   @XFD::VariableReference::ISA = qw( XFD::Op );
sub XFD::VariableReference::is_constant { 0 }
sub XFD::VariableReference::result_type { "any" }
sub XFD::VariableReference::as_immed_code {
    my $self = shift;
    my $var_name = $self->[0];
    return "\$d->_look_up_var( '$var_name' )";
}

###############################################################################
##
## Operators (other than Union)
##
sub _compile_relational_ops {
    my ( $name, $numeric_op, $string_op ) = @_;
    for ( qw( boolean number string ) ) {
        my $class = "XFD::Operator::${_}_${name}";
        my $op = $_ ne "string" ? $numeric_op : $string_op;
        
        no strict "refs";
        @{"${class}::ISA"} = qw( XFD::BooleanFunction );
        eval <<CODE_END;
            sub ${class}::parm_type { "$_" }
            sub ${class}::as_immed_code {
                shift->build_expr( 2, 2, \$_[0], sub { "( \$_[0] $op \$_[1] )" } );
            }
CODE_END
    }
}


sub relational_op {
    my ( $op_name, $parm1, $parm2 ) = @_;
    my $foo = $parm1->result_type . "|" . $parm2->result_type;
    for (qw( boolean number string )) {
        if ( 0 <= index $foo, $_ ) {
            my $class = "XFD::Operator::${_}_${op_name}";
            return $class->new( $parm1, $parm2 );
        }
    }
    die "Couldn't discern a parameter type in $foo";
}


sub _compile_math_op {
    my ( $name, $op ) = @_;

    my $class = "XFD::Operator::${name}";
    
    no strict "refs";
    @{"${class}::ISA"} = qw( XFD::NumericFunction );
    eval <<CODE_END;
        sub ${class}::as_immed_code {
            shift->build_expr( 2, 2, \$_[0], sub { "( \$_[0] $op \$_[1] )" } );
        }
CODE_END
}


sub math_op {
    my ( $name, $parm1, $parm2 ) = @_;
    my $class = "XFD::Operator::$name";
    return $class->new( $parm1, $parm2 );
}

##########
   @XFD::Parens::ISA = qw( XFD::Function );
sub XFD::Parens::result_type   {      shift->[0]->result_type               }
sub XFD::Parens::as_immed_code { join shift->[0]->as_immed_code( @_ ), "( ", " )" }
##########
   @XFD::Negation::ISA = qw( XFD::NumericFunction );
sub XFD::Negation::as_immed_code {
    shift->build_expr( 1, 1, $_[0],
        sub { "do { my \$n = $_[0]; \$n eq 'NaN' ? \$n : 0-\$n }" }
    );
}
##########
   @XFD::Operator::and::ISA = qw( XFD::BooleanFunction );
sub XFD::Operator::and::as_immed_code {
    shift->build_expr( 2, 2, $_[0], sub { "( $_[0] and $_[1] )" } );
}
##########
   @XFD::Operator::or::ISA = qw( XFD::BooleanFunction );
sub XFD::Operator::or::as_immed_code {
    shift->build_expr( 2, 2, $_[0], sub { "( $_[0] or $_[1] )" } );
}
##########
##
## Relational ops
##
_compile_relational_ops equals     => "==", "eq";
_compile_relational_ops not_equals => "!=", "ne";
_compile_relational_ops lt         => "<" , "lt";
_compile_relational_ops lte        => "<=", "le";
_compile_relational_ops gt         => ">" , "gt";
_compile_relational_ops gte        => ">=", "ge";
##########
_compile_math_op addition       => "+";
_compile_math_op subtraction    => "-";
_compile_math_op multiplication => "*";
_compile_math_op division       => "/";
_compile_math_op modulus        => "%";

###############################################################################
##
## Location Path Tests
##
## As the
## grammar parses a location path, it stringse these objects together.
## When a location path has been completely assembed, the objects
## are converted in to code.  This is necessary because paths are recognized
## from left to right by the grammar, but need to be assembled right
## to left.  We could use closure to accomplish this, but closures leak
## in different ways in different perls.
##
@XFD::doc_node::ISA = qw( XFD::PathTest );

sub XFD::doc_node::optim_signature { ref shift }

sub XFD::doc_node::possible_event_type_map {
    ## This is because there's no surrounding context for this, ever,
    ## so we need to bootstrap $context->{PossibleEventTypes} by
    ## circumventing XSF::PathTest::possible_event_types() with our
    ## own.  Defining *this* sub cause our possible_event_types() to
    ## be called.
    confess "this is a DUMMY to force possibe_event_types to be called";
}


## TODO: see if we really need end_document here (and end_element in other places)
#sub XFD::doc_node::possible_event_types { qw( start_document end_document ) }
sub XFD::doc_node::possible_event_types { qw( start_document end_document ) }

sub XFD::doc_node::incr_code_template {
    my $self = shift;
    return <<CODE_END;
## doc_node
  <NEXT>
# end doc_node
CODE_END
}


##########
@XFD::self_node::ISA = qw( XFD::PathTest );

sub XFD::self_node::curry_tests {
    my $self = shift;

    ## If this is *not* a standalone, then it's basically a noop, so
    ## delegate to the next test.
    return $self->[_next]->curry_tests
        if defined $self->[_next];

    ## Otherwise, return every node test type.  This happens when '.'
    ## is the entire location path
    @all_curry_tests;
}

# This little method lets rules like '@*' => [ 'string()' => sub { ... } ]
# work: it checks to see if it will only be called in an attribute context and
# returns the current node.  This works because 'string()' is really
# 'string(.)', which is really a function call to string() with self_node
# as its first parameter.  So, if self_node can only be interpreted in
# attribute context, then it returns $ctx as immediate code.  Otherwise
# it lets XFD::PathTest precursorize thie and tell get_expr_code to
# wait and then look in the postponement for its answer.

# This is an awkward little kludge,
# but I haven't taken the time to figure out how the compiler should handle
# the general case of this situation.  TODO: Probably do more than just
# attributes here; probably comment and PI.  Perhaps also characters, but
# then the user gets no catenation.  hmmm.
sub XFD::self_node::immed_code_template {
    my $self = shift;
    my ( $context ) = @_;

#warn $context->{PossiblesSetBy}->op_type, ": ", join ",", @{$context->{PossibleEventTypes}};

    return "\$ctx"
        if $context->{PossibleEventTypes}
            && @{$context->{PossibleEventTypes}} == 1
            && $context->{PossibleEventTypes}->[0] eq "attribute";

    return $self->XFD::PathTest::immed_code_template( @_ );
}


sub XFD::self_node::incr_code_template { "<NEXT>" }

##########
@XFD::node_name::ISA = qw( XFD::PathTest );

sub XFD::node_name::curry_tests { qw( start_element attribute ) }

sub XFD::node_name::possible_event_type_map { {
    'start_element' => [qw( start_element )],
    'attribute'     => [qw( attribute     )],
} }

sub XFD::node_name::useful_event_contexts { qw( start_element end_element attribute ) }

sub XFD::node_name::condition {
    my $self = shift;
    my ( $ctx_expr ) = @_;

    return "$ctx_expr\->{Node}->{Name} eq '$self->[0]'";
}

sub XFD::node_name::incr_code_template {
    my $self = shift;
    my $cond = $self->condition( "\$ctx" );

    return <<CODE_END;
if ( $cond ) {
  emit_trace_SAX_message "EventPath: node name '$self->[0]' found" if is_tracing;
  <NEXT>}
CODE_END
}

sub XFD::node_name::immed_code_template {
    my $self = shift;
    my $cond = $self->condition( "\$_" );

    return <<CODE_END;
grep ## node name '$self->[0]'
  $cond,
<NEXT>
CODE_END
}

##########
@XFD::node_local_name::ISA = qw( XFD::node_name );

sub XFD::node_local_name::condition {
    my $self = shift;
    my ( $ctx_expr ) = @_;

    return "$ctx_expr\->{Node}->{LocalName} eq '$self->[0]'";
}

sub XFD::node_local_name::incr_code_template {
    my $self = shift;
    my $cond = $self->condition( "\$ctx" );

    return <<CODE_END;
if ( $cond ) {
  emit_trace_SAX_message "EventPath: node local_name '$self->[0]' found" if is_tracing;
  <NEXT>}
CODE_END
}

##########
@XFD::namespace_test::ISA = qw( XFD::PathTest );

sub XFD::namespace_test::new {
    my $self = shift->XFD::PathTest::new( @_ );

    die "Namespaces option required to support '$self->[0]' match\n"
        unless defined $dispatcher->{Namespaces};

#    ( $self->[0] ) = $self->_parse_ns_uri_and_localname( $self->[0] );

    return $self;
}

sub XFD::namespace_test::curry_tests { qw( start_element attribute ) }

sub XFD::namespace_test::possible_event_type_map { {
    'start_element' => [qw( start_element )],
    'attribute'     => [qw( attribute     )],
} }

sub XFD::namespace_test::useful_event_contexts { qw( start_element end_element attribute ) }

sub XFD::namespace_test::condition {
    my $self = shift;
    my ( $ctx_expr ) = @_;

    return 
       "$ctx_expr\->{Node}->{NamespaceURI} eq '$self->[0]'";
}

sub XFD::namespace_test::incr_code_template {
    my $self = shift;
    my $cond = $self->condition( "\$ctx" );

    return <<CODE_END;
if ( $cond ) {
  emit_trace_SAX_message "EventPath: node namespace '$self->[0]' found" if is_tracing;
  <NEXT>}
CODE_END
}

sub XFD::namespace_test::immed_code_template {
    my $self = shift;
    my $cond = $self->condition( "\$_" );

    return <<CODE_END;
grep ## node namespace '$self->[0]'
  $cond,
<NEXT>
CODE_END
}

##########
## TODO: implement this as primary nodetype for this axis and not
## a name test.
@XFD::any_node_name::ISA = qw( XFD::PathTest );

sub XFD::any_node_name::curry_tests { qw( start_element attribute ) }

sub XFD::any_node_name::incr_code_template { <<CODE_END }
## any node name
if ( \$ctx->{EventType} eq "start_element" || \$ctx->{EventType} eq "attribute" ) {
  emit_trace_SAX_message "EventPath: node name '*' found" if is_tracing;
  <NEXT>
} # any node name
CODE_END

##########
@XFD::union::ISA = qw( XFD::PathTest );

sub XFD::union::new {
    my $class = shift;
    ## No _next, so don't use base class' new().
    return bless [@_], $class;
}

sub XFD::union::optim_signature { ref shift }

sub XFD::union::add { push @{shift()}, @_ }

sub XFD::union::set_next { $_->set_next( @_ ) for @{shift()} }

## get_kids/set_kids is used by external code only, like the optimizer
sub XFD::union::get_kids { map $_->isa( "XFD::union" ) ? $_->get_kids : $_, @{shift()} }
sub XFD::union::set_kids { my $self = shift; @$self = @_ }

sub XFD::union::curry_tests {
    my $self = shift;

    my %tests;

    for ( @$self ) {
        for ( $_->curry_tests ) {
            $tests{$_} = undef;
        }
    }

    return keys %tests;
}


sub XFD::union::fixup {
    my $self = shift;

    ## Test this here because the optimizer *does* put unions in front
    ## of things the user should not be able to do.

    for ( @$self ) {
        die
"XPath's union operator ('|') doesn't work on a ", ref $_, ", perhaps 'or' is needed.\n"
            unless $_->isa( "XFD::PathTest" );
    }

    $self->XFD::PathTest::fixup( @_ );
}


sub XFD::union::as_incr_code {
    my $self = shift;

    return ""                             if @$self == 0;
    return $self->[0]->as_incr_code( @_ ) if @$self == 1;

    return join "",
        map( ( "# union\n", $_->as_incr_code( @_ ) ), @$self ),
        "# end union\n" ;
}

##########
##
## An XFD::Rule is a special "noop" op that allows compilation
## exceptions to be labelled with a rule's pattern.
##
@XFD::Rule::ISA = qw( XFD::PathTest );

sub XFD::Rule::fixup {
    my $self = shift;

    eval {
        $self->XFD::PathTest::fixup( @_ );
        1;
    } or do {
        $@ =~ s/\n/ in expression $self->[0]\n/;
        die $@;
    }
}


sub XFD::Rule::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;

    $context = { %$context };

    my $r = eval {
        $self->[_next]->as_incr_code( $context );
    };
    unless ( defined $r ) {
        $@ =~ s/\n/ in expression $self->[0]\n/;
        die $@;
    }
    return $r;
}

##########
@XFD::predicate::ISA = qw( XFD::PathTest );

## new() might get a location path passed as a param, or find them in the
## predicates.  The former happens when st. like [@foo] occurs, the latter
## when [@foo=2] occurs (since the "=" converted @foo to a predicate).

sub XFD::predicate::new {
    return shift->XFD::PathTest::new( XFD::Function::boolean->new( @_ ) );
}

## Disable folding of predicates for now.  What we really need to do
## is cat up all the signatures of the code in the predicate in to the
## signature so only identical ones will be optimized.
##
## A better approace longer term might be to hoist the predicate
## precursors in fixup phase so they are normal ops and would get
## optimized normally.
sub XFD::predicate::optim_signature { int shift }

sub _expr() { 0 }

sub XFD::predicate::curry_tests {
    my $self = shift;

    ## If there's something after us, delegate.
    return $self->[_next]->curry_tests
        if defined $self->[_next];

    ## Otherwise, return every node test type.
    @all_curry_tests;
}


sub XFD::predicate::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;

    return get_expr_code "predicate", $self->[_expr], undef, undef, $self->[_next], @_;
}

###############################################################################
##
## Axes
##

##
## The grammar calls axis(), which returns an object.
##
sub axis {
    my $class = "XFD::Axis::$_[0]";
    $class =~ s/_/<UNDERSCORE_NOT_ALLOWED>/g;
    $class =~ s/-/_/g;
    die "'$_[0]' is not a valid EventPath axis\n"
        unless $class->can( "new" );
    return $class->new;
}

   @XFD::Axis::ISA = qw( XFD::PathTest );
sub XFD::Axis::op_type { shift->XFD::Op::op_type . "::" }
sub XFD::Axis::principal_event_type { "start_element" }

## Axes have no parameters and are inherently foldable, so return the
## type of the axis.  Axis ops that need to be curried for different
## event types can't be folded.
sub XFD::Axis::optim_signature {
    my $self = shift;
    join "", ref $self, "(", $self->[_next]->curry_tests, ":", $self->principal_event_type, ")";
}


##########
   @XFD::Axis::attribute::ISA = qw( XFD::Axis );
sub XFD::Axis::attribute::curry_tests { ( "start_element" ) }
sub XFD::Axis::attribute::principal_event_type { "attribute" }
sub XFD::Axis::attribute::possible_event_type_map {
#warn "HI!";
{
    start_element => [qw( attribute )],
} }
    
sub XFD::Axis::attribute::useful_event_contexts { qw( start_element end_element ) }

#X This is an aborted attempt to make things following an attribute:: 
#X run immediately.
#Xsub XFD::Axis::attribute::as_incr_code {  ## not ..._template()!
sub XFD::Axis::attribute::incr_code_template {
    my $self = shift;
#X    my ( $context ) = @_;
#X
#X    $self->check_context( $context );

    ## node type tests only apply to certain event types, so
    ## we only curry to those events.  This makes EventType
    ## tests run-time noops, and simplifies others (node_name)
    ## because they do not need to test $ctx->{EventType}.
    my @curry_tests = grep $_ eq "attribute", $self->[_next]->curry_tests;

    die $self->op_type, " followed by ", $self->[_next]->op_type,
        " can never match\n" unless @curry_tests;

#X    local $context->{Axis}               = $self->op_type;
#X    local $context->{PrincipalEventType} = $self->principal_event_type;
#X    local $context->{PossibleEventTypes} = [ $self->possible_event_types( @_ ) ];
#X
#X    my $next_code = $self->[_next]->as_immed_code( $context );
#X
#X    return $self->insert_next_in_to_template( <<CODE_END, $next_code ) if @curry_tests == 1;

    return <<CODE_END if @curry_tests == 1;
emit_trace_SAX_message "EventPath: queuing for attribute::" if is_tracing;
push \@{\$ctx->{ChildCtx}->{$curry_tests[0]}}, [ ## attribute::
  sub {
    my ( \$postponement ) = \@_;
    emit_trace_SAX_message "EventPath: in attribute \$ctx->{Node}->{Name}" if is_tracing;
    <NEXT>
  },
  \$postponement,
]; # attribute::
CODE_END

    my $curry_code = join "\n",
        map "  push \@{\$ctx->{ChildCtx}->{$_}}, \$queue_record;",
            @curry_tests;

    return <<CODE_END;
## attribute::
{
  ## Curry the rest of the location path tests
  ## to be handled in the appropriate attribute events.
  my \$queue_record = [
    sub {
      my ( \$postponement ) = \@_;
      emit_trace_SAX_message "EventPath: in attribute" if is_tracing;
      <NEXT>
    },
    \$postponement,
  ];
  emit_trace_SAX_message "EventPath: queuing for attribute::" if is_tracing;
$curry_code
} # attribute::
CODE_END
}


sub XFD::Axis::attribute::immed_code_template {
    my $self = shift;
    ## Do a little belated optimization here
    ## TODO: Generalize this to handle intervening XFD::unions and
    ## to work for node_name tests.
    my $kid = $self->[_next];
    if ( $kid && $kid->isa( "XFD::namespace_test" ) ) {
        my $gkid = $kid->[_next];
        if ( $gkid && $gkid->isa( "XFD::node_local_name" ) ) {
            ## Its an attribute::foo:bar expression, which can
            ## be optimized very nicely, thank you
            my $ns_uri = $kid->[0];
            my $local_name = $gkid->[0];
            return <<CODE_END;
( ## attribute::prefix:name
  exists \$ctx->{Node}->{Attributes}->{'{$ns_uri}$local_name'}
    ? { ## A context for the found attribute
      EventType => 'attribute',
      Node      => \$ctx->{Node}->{Attributes}->{'{$ns_uri}$local_name'},
      Parent    => \$ctx,
    }
    : ()
)
CODE_END
        }
    }

    my $sort_code = $dispatcher->{SortAttributes} ? <<'CODE_END' : "";
  } sort {
      ## Put attributes in a reproducable order, mostly for testing
      ## purposes.
      ## TODO: Look for Node->{AttributeOrder} here
      ( \$a->{Name}         || "" ) cmp ( \$b->{Name}         || "" )
CODE_END

    return <<CODE_END;
( ## attribute::
  <NEXT>
  map {
    my \$ctx = {
      EventType => 'attribute',
      Node      => \$_,
      Parent    => \$ctx,
    };
    emit_trace_SAX_message "built attribute event ", _ev \$ctx if is_tracing;
    \$ctx;
$sort_code
  } values %{\$ctx->{Node}->{Attributes}}
) # attribute::
CODE_END
}


##########
   @XFD::Axis::child::ISA = qw( XFD::Axis );
sub XFD::Axis::child::possible_event_type_map { {
    start_document => [qw( start_prefix_mapping start_element comment processing_instruction )],
    start_element  => [qw( start_prefix_mapping start_element comment processing_instruction characters )],
} }

sub XFD::Axis::child::useful_event_contexts { qw( start_document start_element ) }

sub XFD::Axis::child::incr_code_template {
    my $self = shift;

    ## node type tests only apply to certain event types, so
    ## we only curry to those events.  This makes EventType
    ## tests run-time noops, and simplifies others (node_name)
    ## because they do not need to test $ctx->{EventType}.
    my @curry_tests =
        grep exists $child_curry_tests{$_}, $self->[_next]->curry_tests;

    die $self->op_type, " followed by ", $self->[_next]->op_type,
        " can never match\n" unless @curry_tests;

    return <<CODE_END if @curry_tests == 1;
## child::
emit_trace_SAX_message "EventPath: queuing for child::" if is_tracing;
push \@{\$ctx->{ChildCtx}->{$curry_tests[0]}}, [  ## child::
  sub {
    my ( \$postponement ) = \@_;
    <NEXT>
  },
  \$postponement,
]; # end child::
CODE_END

    my $curry_code = join "\n",
        map "  push \@{\$ctx->{ChildCtx}->{$_}}, \$queue_record;",
            @curry_tests;

    return <<CODE_END;
{ ## child::
  my \$queue_record = [
    sub {
      my ( \$postponement ) = \@_;
      <NEXT>
    },
    \$postponement,
  ];
  emit_trace_SAX_message "EventPath: queuing for child::" if is_tracing;
$curry_code
} # child::
CODE_END
}


##########
   @XFD::Axis::descendant_or_self::ISA = qw( XFD::Axis );

sub XFD::Axis::descendant_or_self::possible_event_type_map { {
    ## This is odd: we tell the caller that we could call our kids for
    ## any of these when called on a start_document.  And, literally,
    ## thats' true.  But I'd like to have it set up so that
    ## this is unwound after a start_document so it only queues for
    ## start_element *there*, but then queues for all of them other
    ## places.  That's just for neatness' sake; there would be minimal
    ## performance improvement.  And it would take extra generated code,
    ## I think.
    ## these in start_document.  
    'start_document' => [qw( start_prefix_mapping start_element comment processing_instruction characters )],
    'start_element'  => [qw( start_prefix_mapping start_element comment processing_instruction characters )],
}; }

## useful in any event context, even though self:: alone would be
## more appropriate in most.

sub XFD::Axis::descendant_or_self::as_incr_code {
    return shift->XFD::Axis::as_incr_code( @_ );
}

sub XFD::Axis::descendant_or_self::incr_code_template {
    my $self = shift;

    ## node type tests only apply to certain event types, so
    ## we only curry to those events.  This makes EventType
    ## tests run-time noops, and simplifies others (node_name)
    ## because they do not need to test $ctx->{EventType}.
    ## We always curry to start_element to propogate the tests down
    ## the chain.  Unfortunately, this 

    my %seen;
    my @curry_tests =
        grep ! $seen{$_}++ && exists $child_curry_tests{$_},
            $self->[_next]->curry_tests, "start_element";

    die $self->op_type, " followed by ", $self->[_next]->op_type,
        " can never match\n" unless @curry_tests;

    return <<CODE_END if @curry_tests == 1;
{ ## descendant-or-self::
  my \$sub = sub {
    my ( \$sub, \$postponement ) = \@_;

    emit_trace_SAX_message "EventPath: queuing for descendant-or-self::" if is_tracing;
    push \@{\$ctx->{ChildCtx}->{$curry_tests[0]}}, [ \$sub, \$sub, \$postponement ];
    ## ...run it on this node (aka "self")
    <NEXT>
  };
  \$sub->( \$sub, \$postponement );
} # descendant-or-self::
CODE_END

    my $curry_code = join "\n",
        map "    push \@{\$ctx->{ChildCtx}->{$_}}, \$queue_record;",
            @curry_tests;

    return <<CODE_END;
{ ## descendant-or-self::
  my \$sub = sub {
    my ( \$sub, \$postponement ) = \@_;

    emit_trace_SAX_message "EventPath: queuing for descendant-or-self::" if is_tracing;
    my \$queue_record = [ \$sub, \$sub, \$postponement ];
$curry_code
    ## ...run it on this node (aka "self")
    <NEXT>
  };
  \$sub->( \$sub, \$postponement );
} # descendant-or-self::
CODE_END
}


##########
   @XFD::Axis::end::ISA = qw( XFD::Axis::end_element );
#   @XFD::Axis::end::ISA = qw( XFD::Axis );
#sub XFD::Axis::end::principal_event_type  { "start_element" }
#sub XFD::Axis::end::possible_event_type_map  { {
#    start_document => [qw( end_document )],
#    start_element  => [qw( end_element )],
#} }
#sub XFD::Axis::end::useful_event_contexts { qw( start_document start_element ) }
#
#sub XFD::Axis::end::as_incr_code {  ## not ..._template()!
#    my $self    = shift;
#    my ( $context ) = @_;
#
#    $self->check_context( $context );
#
#    ## This is the lengthy one, as it needs to curry itself
#    ## until the end element rolls around, while playing
#    ## nicely with postponements.
#
#    ## TODO: check how this interacts with nodeset-returning
#    ## paths.
#
#    local $context->{Axis} = $self->op_type;
#
#    local $context->{PrincipalEventType} = $self->principal_event_type;
#    local $context->{PossibleEventTypes} = [ $self->possible_event_types( @_ ) ];
#    local $context->{PossiblesSetBy} = $self;
#
#    if ( ! defined $context->{precursorize_action} ) {
#        ## There are no predicates to leftwards
#        local $context->{delay_to_end} = 1;
#
#        ## This is more like self:: than child::, no need to
#        ## wrap the next set of tests.
#        return $self->[_next]->as_incr_code( $context );
#    }
#    else {
#        ## There's a predicate to our left that's set the various
#        ## precursor... and action_wrapper, so dance with it...
#
#        ## the 'action' pushes the context on to the postponement's
#        ## list of contexts.  We want that to occur in the end_document.
#        my $action_code = <<CODE_END;
#push \@{\$ctx->{EndSubs}}, [ 
#  sub {
#    my ( \$ctx ) = \@_;
#    emit_trace_SAX_message "EventPath: running end::" if is_tracing;
#    <ACTION>
#  },
#  \$ctx
#];
#CODE_END
#
#        _replace_NEXT $action_code, $context->{precursorize_action}, "<ACTION>";
#
#        local $context->{precursorize_action} = $action_code;
#
#        return $self->[_next]->as_incr_code( $context );
#    }
#}
#
#
##########
   @XFD::Axis::end_document::ISA = qw( XFD::Axis );
sub XFD::Axis::end_document::principal_event_type { "start_document" }
sub XFD::Axis::end_document::possible_event_type_map { {
    start_document => [qw( end_document )],
} }
sub XFD::Axis::end_document::useful_event_contexts { qw( start_document ) }

sub XFD::Axis::end_document::fixup {
    my $self    = shift;
    my ( $context ) = @_;

    ## There are no predicates to leftwards
    local $context->{DelayToEnd} = 1;
    $self->XFD::Axis::fixup( @_ );
}


sub XFD::Axis::end_document::as_incr_code {  ## not ..._template()!
    my $self    = shift;
    my ( $context ) = @_;

    $self->check_context( $context );

    ## This is the lengthy one, as it needs to curry itself
    ## until the end element rolls around, while playing
    ## nicely with postponements.

    ## TODO: check how this interacts with nodeset-returning
    ## paths.

    local $context->{Axis} = $self->op_type;

    local $context->{PrincipalEventType} = $self->principal_event_type;
    local $context->{PossibleEventTypes} = [ $self->possible_event_types( @_ ) ];
    local $context->{PossiblesSetBy} = $self;

    if ( ! defined $context->{precursorize_action} ) {
        ## This is more like self:: than child::, no need to
        ## wrap the next set of tests.
        return $self->[_next]->as_incr_code( $context );
    }
    else {
        ## There's a predicate to our left that's set the various
        ## precursor... and action_wrapper, so dance with it...

        ## The assumption made in the fixup phase is invalid; we
        ## now need to queue an EndSub instead of putting the
        ## action right in to PendingEndActions so that the
        ## postponement can be tested.
        local $context->{IgnoreDelayToEnd} = 1;

        ## the 'action' pushes the context on to the postponement's
        ## list of contexts.  We want that to occur in the end_document.
        my $action_code = <<CODE_END;
push \@{\$ctx->{EndSubs}}, [ 
  sub {
    my ( \$ctx ) = \@_;
    emit_trace_SAX_message "EventPath: running end_document::" if is_tracing;
    <ACTION>
  },
  \$ctx
];
CODE_END

        _replace_NEXT $action_code, $context->{precursorize_action}, "<ACTION>";

        local $context->{precursorize_action} = $action_code;

        return $self->[_next]->as_incr_code( $context );
    }
}


##########
   @XFD::Axis::end_element::ISA = qw( XFD::Axis );
sub XFD::Axis::end_element::possible_event_type_map { {
    start_element => [qw( end_element )],
} }
sub XFD::Axis::end_element::useful_event_contexts { qw( start_document start_element ) }

sub XFD::Axis::end_element::fixup {
    my $self    = shift;
    my ( $context ) = @_;

    ## Tell the Action that it should delay itself to the end_... event
    ## by using PendingEndActions.  This gets overridden in the compile
    ## phase by setting IgnoreDelayToEnd if need be.
    ##
    ## Doing this here facilitates optimizing end:: into child:: in
    ## certain cases.
    local $context->{DelayToEnd} = 1;
    $self->XFD::Axis::fixup( @_ );
}


sub XFD::Axis::end_element::as_incr_code {  ## not ..._template()!
    my $self    = shift;
    my ( $context ) = @_;

    $self->check_context( $context );

    ## This is the lengthy one, as it needs to curry itself
    ## until the end element rolls around, while playing
    ## nicely with postponements.

    ## end-element:: is a bit like child::, except it selects the
    ## child's end element.  So, it queues up something for the
    ## child's start_element event (so, for instance, the node_name
    ## or attr tests or predicates, etc. run), which then queue
    ## up the action for the child's EndSubs.

    ## TODO: check how this interacts with nodeset-returning
    ## paths.

    local $context->{PrincipalEventType} = $self->principal_event_type;
    local $context->{Axis} = $self->op_type;
    local $context->{PossibleEventTypes} = [ $self->possible_event_types( @_ ) ];
    local $context->{PossiblesSetBy} = $self;

    if ( ! defined $context->{precursorize_action} ) {
        ## There are no predicates to leftwards

        my $code = <<CODE_END;
## end_element::
emit_trace_SAX_message "EventPath: queuing for end_element::" if is_tracing;
push \@{\$ctx->{ChildCtx}->{start_element}}, [
  sub {
    my ( \$postponement ) = \@_;
    <NEXT>
  },
  \$postponement
];
CODE_END

        _replace_NEXT $code, $self->[_next]->as_incr_code( $context );
        return $code;
    }
    else {
        ## There's a predicate to our left that's set the various
        ## precursor... and action_wrapper, so dance with it...

        ## The assumption made in the fixup phase is invalid; we
        ## now need to queue an EndSub instead of putting the
        ## action right in to PendingEndActions so that the
        ## postponement can be tested.
        ## TODO: see if we can move the detection of precursors in to
        ## the fixup phase so we can avoid setting IgnoreDelayToEnd
        ## in that case.
        local $context->{IgnoreDelayToEnd} = 1;

        ## the 'action' pushes the context on to the postponement's
        ## list of contexts.  We want that to occur in the end_element.
        my $action_code = <<CODE_END;
emit_trace_SAX_message "EventPath: queuing for end_element::" if is_tracing;
push \@{\$ctx->{EndSubs}}, [ 
  sub {
    emit_trace_SAX_message "EventPath: running end_element::" if is_tracing;
    <ACTION>
  },
];
CODE_END

        _replace_NEXT $action_code, $context->{precursorize_action}, "<ACTION>";

        local $context->{precursorize_action} = $action_code;

        my $code = <<CODE_END;
emit_trace_SAX_message "EventPath: queuing for end_element::" if is_tracing;
push \@{\$ctx->{ChildCtx}->{start_element}}, [
  sub {
    my ( \$postponement ) = \@_;
    <NEXT>
  },
  \$postponement
];
# end_element::
CODE_END

        _replace_NEXT $code, $self->[_next]->as_incr_code( $context );

        return $code;
    }
}


##########
   @XFD::Axis::self::ISA = qw( XFD::Axis );
## don't define possible_node_types; pass the current ones
## through from LHS to RHS.
sub XFD::Axis::self::possible_node_types { () } ## () means "all".
sub XFD::Axis::self::incr_code_template { "<NEXT>" }

##########
   @XFD::Axis::start::ISA = qw( XFD::Axis::start_element );
#   @XFD::Axis::start::ISA = qw( XFD::Axis );
#sub XFD::Axis::start::principal_event_type { "start_element" }
#sub XFD::Axis::start::possible_event_type_map { {
#    start_document => [qw( start_document )],
#    start_element  => [qw( start_element  )],
#} }
#sub XFD::Axis::start::useful_event_contexts {qw( start_document start_element )}
#sub XFD::Axis::start::incr_code_template { "<NEXT>" }

##########
   @XFD::Axis::start_document::ISA = qw( XFD::Axis );
sub XFD::Axis::start_document::principal_event_type { "start_document" }
sub XFD::Axis::start_document::possible_event_type_map { {
    start_document => [qw( start_document )],
} }
sub XFD::Axis::start_document::useful_event_contexts { qw( start_document ) }
sub XFD::Axis::start_document::incr_code_template { "<NEXT>" }

##########
   @XFD::Axis::start_element::ISA = qw( XFD::Axis );
sub XFD::Axis::start_element::possible_event_type_map { {
    start_element => [qw( start_element )],
} }
sub XFD::Axis::start_element::useful_event_contexts { qw( start_document start_element ) }
sub XFD::Axis::start_element::incr_code_template {
    my $self = shift;

    return <<CODE_END;
## start_element::
emit_trace_SAX_message "EventPath: queuing for start-element::" if is_tracing;
push \@{\$ctx->{ChildCtx}->{start_element}}, [
  sub {
    my ( \$postponement ) = \@_;
    <NEXT>
  },
  \$postponement
];
CODE_END
}


###############################################################################
##
## Node Type Tests
##
@XFD::EventType::ISA = qw( XFD::PathTest );

## Node type tests work by only getting
## curried to the appropriate event types.
sub XFD::EventType::incr_code_template { "<NEXT>" }
sub XFD::EventType::op_type { shift->XFD::Op::op_type . "()" }

##########
   @XFD::EventType::node::ISA = qw( XFD::EventType );
## node() has no parameters and is inherently foldable.
## node() ops that need to be curried for different
## event types can't be folded.
sub XFD::EventType::node::optim_signature {
    my $self = shift;
    join "", ref $self, "(", defined $self->[_next] ? $self->[_next]->curry_tests : (), ")";
}


sub XFD::EventType::node::curry_tests {
    my $self = shift;
    return $self->[_next]->curry_tests
        if defined $self->[_next];

    return @all_curry_tests, "start_prefix_mapping", "end_element", "end_document";
}
##########
   @XFD::EventType::text::ISA = qw( XFD::EventType );
sub XFD::EventType::text::possible_event_type_map { {
    start_element => [qw( characters )],
} }
sub XFD::EventType::text::useful_event_contexts { qw( start_element ) }
sub XFD::EventType::text::curry_tests { "characters" }
##########
   @XFD::EventType::comment::ISA = qw( XFD::EventType );
sub XFD::EventType::comment::possible_event_type_map { {
    start_document => [qw( characters )],
    start_element  => [qw( characters )],
} }
sub XFD::EventType::comment::useful_event_contexts { qw( start_document start_element ) }
sub XFD::EventType::comment::curry_tests { "comment" }
##########
   @XFD::EventType::processing_instruction::ISA = qw( XFD::EventType );
sub XFD::EventType::processing_instruction::possible_event_type_map { {
    start_document => [qw( processing_instruction )],
    start_element  => [qw( processing_instruction )],
} }
sub XFD::EventType::processing_instruction::useful_event_contexts { qw( start_document start_element ) }
sub XFD::EventType::processing_instruction::curry_tests { "processing_instruction" }
##########
   @XFD::EventType::principal_event_type::ISA = qw( XFD::EventType );
sub XFD::EventType::principal_event_type::curry_tests {
    my $self = shift;
    ## 'twould be good if we could see PrincipalEventType here.
    ## TODO: pass $context down through curry_tests.
    return @all_curry_tests;
}

sub XFD::EventType::principal_event_type::incr_code_template {
    my $self = shift;
    my ( $context ) = @_;

    my $desired_event_type = $context->{PrincipalEventType};
    my @possible_event_types = @{$context->{PossibleEventTypes} || []};
#warn @possible_event_types;

    return "<NEXT>"
        if @possible_event_types == 1
            && $possible_event_types[0] eq $desired_event_type;

    local $" = ", ";
    return <<CODE_END;
## ::*
## possible event types: @possible_event_types
if ( \$ctx->{EventType} eq "$desired_event_type" ) {
  emit_trace_SAX_message "EventPath: principal event type $desired_event_type found" if is_tracing;
  <NEXT>
} # ::*
CODE_END
}

#Xsub XFD::EventType::principal_event_type::immed_code_template {
#X    my $self = shift;
#X    my ( $context ) = @_;
#X
#X    my $desired_event_type = $context->{PrincipalEventType};
#X    my @possible_event_types = @{$context->{PossibleEventTypes} || []};
#X
#X    return "<NEXT>"
#X        if @possible_event_types == 1
#X            && $possible_event_types[0] eq $desired_event_type;
#X
#X    return qq{\$ctx->{EventType} eq "$desired_event_type" ? <NEXT> : ()};
#X}

###############################################################################
##
## Optimizer Ops
##
## The optimizer rearranges and tears apart the op tree in to multiple
## trees.  Those trees need to be compiled a bit differently and 
## need to create a suitable compiletime environment for their children.
##

##########
   @XFD::Optim::attribute::ISA = qw( XFD::union );
sub XFD::Optim::attribute::possible_event_types { qw( start_element ) }
sub XFD::Optim::attribute::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;
    local $context->{PossibleEventTypes} = [qw( attribute )];
    $self->XFD::union::as_incr_code( @_ );
}

##########
   @XFD::Optim::characters::ISA = qw( XFD::union );
sub XFD::Optim::characters::possible_event_types { qw( start_element ) }
sub XFD::Optim::characters::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;
    local $context->{PossibleEventTypes} = [qw( characters )];
    $self->XFD::union::as_incr_code( @_ );
}

##########
   @XFD::Optim::comment::ISA = qw( XFD::union );
sub XFD::Optim::comment::possible_event_types {
    qw( start_document start_element )
}
sub XFD::Optim::comment::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;
    local $context->{PossibleEventTypes} = [qw( comment )];
    $self->XFD::union::as_incr_code( @_ );
}

##########
   @XFD::Optim::processing_instruction::ISA = qw( XFD::union );
sub XFD::Optim::processing_instruction::possible_event_types {
    qw( start_document start_element )
}
sub XFD::Optim::processing_instruction::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;
    local $context->{PossibleEventTypes} = [qw( processing_instruction )];
    $self->XFD::union::as_incr_code( @_ );
}

##########
   @XFD::Optim::start_element::ISA = qw( XFD::union );
sub XFD::Optim::start_element::possible_event_types { qw( start_element ) }
sub XFD::Optim::start_element::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;
    local $context->{PossibleEventTypes} = [qw( start_element )];
    $self->XFD::union::as_incr_code( @_ );
}

##########
   @XFD::Optim::start_prefix_mapping::ISA = qw( XFD::union );
sub XFD::Optim::start_prefix_mapping::possible_event_types { qw( start_document start_element ) }
sub XFD::Optim::start_prefix_mapping::as_incr_code {
    my $self = shift;
    my ( $context ) = @_;
    local $context->{PossibleEventTypes} = [qw( start_prefix_mapping )];
    $self->XFD::union::as_incr_code( @_ );
}

1;
