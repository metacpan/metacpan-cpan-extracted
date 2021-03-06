package XML::Filter::Dispatcher::Compiler;

$VERSION = 0.000_1;

=head1 NAME

XML::Filter::Dispatcher::Compiler - Compile rulesets in to code

=head1 SYNOPSIS

    use XML::Filter::Dispatcher::Compiler qw( xinline );

    my $c = XML::Filter::Dispatcher::Compiler->new( ... )

    my $code = $c->compile(
        Package     => "My::Filter",
        Rules       => [
            'a/b/c'     => xinline q{warn "found a/b/c"},
        ],
        Output      => "lib/My/Filter.pm",  ## optional
    );

=head1 DESCRIPTION

Most of the options from XML::Filter::Dispatcher are accepted.

NOTE: you cannot pass code references to compile() if you want to write
the $code to disk, they will not survive.  If you want to C<eval $code>,
this is ok.

=head1 METHODS

=over

=cut

@EXPORT_OK = qw( xinline );
%EXPORT_TAGS = ( all => \@EXPORT_OK );
@ISA = qw( Exporter );
use Exporter;

use strict;

use Carp;
use XML::Filter::Dispatcher::Parser;

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = bless { @_ }, $class;

    return $self;
}


=item xinline

Hints to X::F::D that the string is inlinable code.  This is a
requirement when using the compiler and is so far (v.52) ignored
elswhere.  In xinlined code, C<$self> refers to the current dispatcher
and C<$e> refers to the current event's data.  Or you can get that
yourself in C<$_[0]> and C<$_[1]> as in a normal SAX event handling
method.

=cut

sub xinline($) { return \$_[0] }


=item compile

Accepts options that extend and override any previously set for the duration of
the compile(), including the ruleset to compile.

=cut

sub compile {
    my $self = shift;

    ## Clone $self to locally override options
    $self = $self->new( %$self, @_ );

    ## XFD::dispatcher is only needed for the parse & codegen phases.
    local $XFD::dispatcher = $self;

    my $package_name = $self->{Package};

    $self->_parse;

    ## Convert actions to subs, rejecting any that can't be converted
    my @actions_code;
    my @actions_predecls;
    for my $i ( 0..$#{$self->{Actions}} ) {
        local $_ = $self->{Actions}->[$i];
        croak "Can't compile CODE reference actions in to external modules\n"
            if $_->{CodeRef};

        if ( $_->{IsInlineCode} ) {
            my $code = ${$_->{Code}};
            $_->{Code} = "\\&action_$i";
            
            push @actions_predecls, "sub action_$i;\n";

            push @actions_code, <<CODE_END;

#line 1 ${package_name}::action_$i()
sub action_$i { my ( \$self, \$e ) = \@_; $code
}

CODE_END
        }
    }

    my $actions_predecls = join "", @actions_predecls;
    my $actions_code     = join "", @actions_code;
    my $code = $self->_post_process;

## HACK fixup until refactor
$code =~ s/\$cur_self\b/\$XFD::cur_self/g;
$code =~ s/(?<!my )\$ctx(?![a-zA-z_;])/\$XFD::ctx/g;

    my $imports = join " ", @{$self->{Imports} || []};

    my $local_time = localtime;
    my $preamble = $self->{Preamble};
    $preamble = "" unless defined $preamble;

    $preamble = "##PREAMBLE\n$preamble\n## END PREAMBLE\n" if length $preamble;

    $code = <<CODE_END;
package $package_name;

## This is a quick and dirty shoehorning-in; a future version will
## overload start_element, etc, and perhaps not even *be* an
## XML::Filter::Dispatcher.

## AUTOGENERATED: DO NOT HAND EDIT
##
## built on $local_time

\@${package_name}::ISA = qw( XML::Filter::Dispatcher );

use strict;
use XML::Filter::Dispatcher qw( $imports );
use XML::Filter::Dispatcher::Runtime;

use constant is_tracing => defined \$Devel::TraceSAX::VERSION;

## Some more workarounds until we can refactor
sub _ev(\$);
sub _po(\$);
*_ev = \\&XML::Filter::Dispatcher::_ev;
*_ev = \\&XML::Filter::Dispatcher::_ev;
*_po = \\&XML::Filter::Dispatcher::_po;
*_po = \\&XML::Filter::Dispatcher::_po;

BEGIN {
    eval( is_tracing
        ? 'use Devel::TraceSAX qw( emit_trace_SAX_message ); 1'
        : 'sub emit_trace_SAX_message; 1'
    ) or die \$@;
}

my \$doc_sub;

sub start_document {
    my \$self = shift;
    \$self->{DocSub} = \$doc_sub;
    \$self->SUPER::start_document( \@_ );
}

## PREDECLARE ACTION SUBS
$actions_predecls## END ACTION SUBS PREDECLARATIONS

## PATTERN MATCHING
\$doc_sub = sub {
$code};
## END PATTERN MATCHING

$preamble

## ACTIONS
## Put this at the end so the #line directives don't disturb
## error reporting.
$actions_code
## END ACTIONS

1;
CODE_END
    if ( $self->{Debug} ) {
        my $c = $code;
        my $ln = 1;
        $c =~ s{^}{sprintf "%4d|", $ln++}gme;
        warn $c;
    }

    return $code;
}


my @every_names = qw(
    attribute
    characters
    comment
    start_element
    start_prefix_mapping
    processing_instruction
);


sub _parse {
    my $self = shift;

    $self->{OpTree} = undef;
    for ( @every_names ) {
        $self->{"${_}OpTree"} = undef;
        $self->{"${_}Sub"} = undef;
    }

    $self->{Actions} = [];

    while ( @{$self->{Rules}} ) {
        my ( $expr, $action ) = (
            shift @{$self->{Rules}},
            shift @{$self->{Rules}}
        );

        eval {
            XML::Filter::Dispatcher::Parser->parse(
                $self,
                $expr,
                $action,
            );
            1;
        }
        or do {
            $@ ||= "parse returned undef";
            chomp $@;
            die "$@ in EventPath expression '$expr'\n";
        }
    }
}

sub _compile {
    my $self = shift;

    ## XFD::dispatcher is only needed for the parse & codegen phases.
    local $XFD::dispatcher = $self;

    $self->_parse;
    return unless $self->{OpTree};

    my $code = $self->_post_process;

    $code = <<CODE_END;
package XFD;

use XML::Filter::Dispatcher::Runtime;

use strict;

use vars qw( \$cur_self \$ctx );

sub {
my ( \$d, \$postponement ) = \@_;
$code};
CODE_END

    if ( $self->{Debug} ) {
        my $c = $code;
        my $ln = 1;
        $c =~ s{^}{sprintf "%4d|", $ln++}gme;
        warn $c;
    }

    return ( $code, $self->{Actions} );
}


sub _post_process {
    my $self = shift;

    $self->{OpTree}->fixup( {} );

    $self->_optimize
        unless defined $ENV{XFDOPTIMIZE} && ! $ENV{XFDOPTIMIZE}
        || defined $self->{Optimize} && ! $self->{Optimize};

    if ( $self->{Debug} > 1 ) {
        my $g = $self->{OpTree}->as_graphviz;
        for ( map "${_}OpTree", @every_names ) {
            $self->{$_}->as_graphviz( $g )
                if $self->{$_};
        }

        open F, ">foo.png";
        print F $g->as_png;
        close F;
        system( "ee foo.png" );
    }

    my $code = $self->{OpTree}->as_incr_code( {
        FoldConstants => $self->{FoldConstants},
    } );

    for ( @every_names ) {
        my $tree_name = "${_}OpTree";
        my $sub_name  = "${_}Sub";
        next unless exists $self->{$tree_name} && $self->{$tree_name};
        my $sub_code = $self->{$tree_name}->as_incr_code( {
            FoldConstants => $self->{FoldConstants},
        } );

        XFD::_indent $sub_code
            if XFD::_indentomatic() || $self->{Debug};

        $code .= <<CODE_END;
\$cur_self->{$sub_name} = sub {
my ( \$d, \$postponement ) = \@_;
$sub_code}; ## end $sub_name
CODE_END
    }

    XFD::_indent $code if XFD::_indentomatic();

    return $code;
}


## This is a series of subs that call from the main sub down to each
## of the child subs.
sub _optimize {
    my $self = shift;

    @{$self->{OpTree}} = map $self->_optimize_rule( $_ ), @{$self->{OpTree}};

    ## The XFD::Rule ops are only used at compile-time to label exceptions
    ## with the text of the rules.  The folding of common leading ops
    ## foils that by combining several rules' ops in to one tree with (at
    ## least) a common root.  Also, XFD::Rule ops look like unfoldable
    ## ops to this stage of the opimizer.  Get rid of them.
    @{$self->{OpTree}} = map $_->get_next, @{$self->{OpTree}};

    for ( map $self->{"${_}OpTree"}, "", @every_names ) {
        $_ = $self->_combine_common_leading_ops( $_ )
            if $_;
    }
}


sub _optimize_rule {
    my $self = shift;
    my ( $rule ) = @_;

    unless ( $rule->isa( "XFD::Rule" ) ) {
        warn "Odd: found a ",
            $rule->op_type,
            " and not a Rule as a top level Op code\n";
        return $rule;
    }

    my $n = $rule->get_next;

    my @kids = $n->isa( "XFD::union" )
        ? map $self->_optimize_rule_kid( $_ ), $n->get_kids
        : ( $self->_optimize_rule_kid( $n ) );

    ## Capture any optimized code trees in to unions to make codegen easier.
    for ( @every_names ) {
        my $tree_name = "${_}OpTree";
        next unless exists $self->{$tree_name} && $self->{$tree_name};
        $self->{$tree_name} = "XFD::Optim::$_"->new( @{$self->{$tree_name}} );
    }

    return () unless @kids;
    $rule->force_set_next(
        @kids == 1
            ? shift @kids
            : XFD::union->new( @kids )
    );

    return $rule;
}


sub _optimize_rule_kid {
    my $self = shift;
    my ( $op ) = @_;

    if ( $op->isa( "XFD::doc_node" ) ) {
        my $kid = $op->get_next;

        if ( $kid->isa( "XFD::union" ) ) {
            $kid->set_kids( map
                $self->_optimize_doc_node_kid( $_ ),
                $kid->get_kids
            );
            return $kid->get_kids ? $op : ();
        }
        else {
            $op->force_set_next( $self->_optimize_doc_node_kid( $kid ) );
            return $op->get_next ? $op: ();
        }
    }

    return $op;
}


sub _optimize_doc_node_kid {
    my $self = shift;
    my ( $op ) = @_;

    if ( $op->isa( "XFD::Axis::descendant_or_self" ) ) {
        my $kid = $op->get_next;

        if ( $kid->isa( "XFD::union" ) ) {
            $kid->set_kids( map
                $self->_optimize_doc_node_desc_or_self_kid( $_ ),
                $kid->get_kids
            );
            return $kid->get_kids ? $op : ();
        }
        else {
            $op->force_set_next(
                $self->_optimize_doc_node_desc_or_self_kid( $kid )
            );
            return $op->get_next ? $op : ();
        }
    }

    return $op;  ## return it unchanged.
}


sub _optimize_doc_node_desc_or_self_kid {
    my $self = shift;
    my ( $op ) = @_;

    if ( $op->isa( "XFD::EventType::node" ) ) {
        my $kid = $op->get_next;
        if ( $kid->isa( "XFD::union" ) ) {
            $kid->set_kids(
                map
                    $self->_optimize_doc_node_desc_or_self_node_kid( $_ ),
                    $kid->get_kids
            );
            return $op->get_kids ? $op : ();
        }
        else {
            $op->force_set_next(
                $self->_optimize_doc_node_desc_or_self_node_kid( $kid )
            );
            return $op->get_next ? $op : ();
        }
    }

    return $op;
}


sub _optimize_doc_node_desc_or_self_node_kid {
    my $self = shift;
    my ( $op ) = @_;

    if ( $op->isa( "XFD::Axis::end_element" ) ) {
        ## By now, the fixup phase has made end:: replaceable by child::
        ## when there are no precursors before it.  We know there are
        ## no precursors before it at this point in the optimizer because
        ## there are no path segments to our left.  Converting it to
        ## a child:: element will make us able to combine the end::foo tests
        ## with child::foo later.
        
        ## CHEAT: we know that end:: and child:: have the same internal
        ## structure, so reblessing is ok.
        bless $op, "XFD::Axis::child";
    }

    if ( $op->isa( "XFD::Axis::child" ) ) {
        my $kid = $op->get_next;
        if ( $kid->isa( "XFD::node_name" )
            || $kid->isa( "XFD::namespace_test" )
            || $kid->isa( "XFD::node_local_name" )
        ) {
            ## The path is like "A" or "//A": optimize this to
            ## be run directly by start_element().

            push @{$self->{start_elementOpTree}}, $kid;
            return ();
        }

        if ( $kid->isa( "XFD::EventType::node" ) ) {
            ## The path is like "node()" or "//node()": optimize this
            ## to be run directly by
            ## start_element(), comment(), processing_instruction()
            ## and characters().
            my $gkid = $kid->get_next;
            push @{$self->{charactersOpTree}}, $gkid;
            push @{$self->{commentOpTree}}, $gkid;
            push @{$self->{processing_instructionOpTree}}, $gkid;
            push @{$self->{start_elementOpTree}}, $gkid;
            push @{$self->{start_prefix_mappingOpTree}}, $gkid;
            return ();
        }
    }
    elsif ( $op->isa( "XFD::Axis::attribute" ) ) {
        my $kid = $op->get_next;
        if ( $kid->isa( "XFD::node_name" )
            || $kid->isa( "XFD::namespace_test" )
            || $kid->isa( "XFD::node_local_name" )
        ) {
            ## The path is like "@A" or "//@A": optimize this to a special
            ## composite opcode that is run directly by start_element().

            push @{$self->{attributeOpTree}}, $kid;
            return ();
        }
    }

    return $op;
}

#sub _i { my $i = 0; ++$i while caller( $i ); " |" x $i; }
sub _combine_common_leading_ops {
    my $self = shift;
    my ( $op ) = @_;

    Carp::confess unless $op;

    return $op
        if $op->isa( "XFD::Action" );

#warn _i, $op->optim_signature, "\n";;
    if ( $op->isa( "XFD::union" ) ) {
        my %kids;
        for ( $op->get_kids ) {
            push @{$kids{$_->optim_signature}}, $_;
        }

        for ( values %kids ) {
            ## TODO: deal with unions inside unions.
            if ( @$_ > 1 && $_->[0]->can( "force_set_next" ) ) {
#warn _i, "unionizing ", $op->optim_signature, "'s kids ", join( ", ", map $_->optim_signature, @$_ ), "\n";
                $_->[0]->force_set_next(
                    XFD::union->new( map $_->get_next, @$_ )
                );
                splice @$_, 1;
            }
        }

        $op->set_kids(
            map $self->_combine_common_leading_ops( $_ ),
            map @{$kids{$_}}, keys %kids
        );

        return ($op->get_kids)[0] if $op->get_kids == 1;
    }
    else {
        ## TODO: Find these ops and optimize them too.  One is
        ## XFD::SubRules.
        return $op unless $op->can( "force_set_next" );

        $op->force_set_next(
            $self->_combine_common_leading_ops( $op->get_next )
        );
    }

    return $op;
}


=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
