use strict; use warnings;
package assign::0;

our $VERSION = '0.0.17';

use assign::Array;
use assign::Hash;

use Filter::Simple;
use PPI;
use XXX;

our $var_prefix = '___';
our $var_id = 1000;
our $var_suffix = '';

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my $code = $self->{code}
        or die "$class\->new requires 'code' string";
    $self->{line} //= 0;
    $self->{doc} = PPI::Document->new(\$code);
    $self->{doc}->index_locations;
    return $self;
}

# FILTER_ONLY code_no_comments => \&filter;
FILTER_ONLY all => \&filter;

sub filter {
    my ($class) = @_;
    $_ = $class->new(
        code => $_,
        line => ([caller(4)])->[2],
    )->transform();
};

sub debug {
    my ($class, $code) = @_;
    if (ref($code) eq 'SCALAR') {
        $code = $$code;
    } elsif (not ref($code)) {
        if (not -f $code) {
            XXX $code;
            die "Argument to $class\->debug() is not a valid file.\n" .
                "Code strings need to be passed as scalar refs.";
        }
        open my $fh, $code or die "Can't open '$code' for input";
        $code = do { local $/; <$fh> };
    } else {
        die "Invalid arguments for $class->debug(...)";
    }
    $class->new(code => $code)->transform;
}

sub transform {
    my ($self) = @_;

    # Call the various possible assignment transformations:
    $self->transform_assignment_statements_with_decl;
    $self->transform_assignment_statements_no_decl;
    # ... more to come ...

    $self->{doc}->serialize;
}

sub transform_assignment_statements_with_decl {
    my ($self) = @_;

    for my $node ($self->find_assignment_statements_with_decl) {
        my ($decl, $lhs, $oper, @rhs) = $node->schildren;
        my $rhs = join '', map $_->content, @rhs;
        $self->transform_assignment_statement(
            $node, $decl, $lhs, $oper, $rhs,
        );
    }
}

sub transform_assignment_statements_no_decl {
    my ($self) = @_;

    for my $node ($self->find_assignment_statements_no_decl) {
        my $decl = '';
        my ($lhs, $oper, @rhs) = $node->schildren;
        my $rhs = join '', map $_->content, @rhs;
        $self->transform_assignment_statement(
            $node, $decl, $lhs, $oper, $rhs,
        );
    }
}

sub find_assignment_statements_with_decl {
    my ($self) = @_;

    map { $_ ||= []; @$_ }
    $self->{doc}->find(sub {
        my $n = $_[1];
        return 0 unless
            $n->isa('PPI::Statement::Variable') and
            @{[$n->schildren]} >= 5 and
            $n->schild(0)->isa('PPI::Token::Word') and
            $n->schild(0)->content =~ /^(my|our|local)$/ and
            (
                $n->schild(1)->isa('PPI::Structure::Constructor') or
                $n->schild(1)->isa('PPI::Structure::Block')
            ) and
            # or PPI::Structure::Block
            $n->schild(2)->isa('PPI::Token::Operator') and
            $n->schild(2)->content eq '=';
    });
}

sub find_assignment_statements_no_decl {
    my ($self) = @_;

    map { $_ ||= []; @$_ }
    $self->{doc}->find(sub {
        my $n = $_[1];
        return 0 unless
            ref($n) eq 'PPI::Statement' and
            @{[$n->schildren]} >= 4 and
            (
                $n->schild(0)->isa('PPI::Structure::Constructor') or
                $n->schild(0)->isa('PPI::Structure::Block')
            ) and
            $n->schild(1)->isa('PPI::Token::Operator') and
            $n->schild(1)->content eq '=';
    });
}

sub transform_assignment_statement {
    my ($self, $node, $decl, $lhs, $oper, $rhs) = @_;

    $decl = $decl ? $decl->{content} . ' ' : '';
    $oper = $oper->{content};

    my $class =
        $lhs->start->content eq '[' ? 'assign::Array' :
        $lhs->start->content eq '{' ? 'assign::Hash' :
        ZZZ $node, "Unsupported statement";

    my $from;
    my $init = [];
    if ($rhs =~ /^(\$\w+);/) {
        $from = $1;
    } else {
        $from = $self->gen_var;
        push @$init, "my $from = $rhs";
    }

    my $code = $class->new(
        node => $lhs,
    )->parse->gen_code($decl, $oper, $from, $init);

    $self->replace_statement_node($node, $code);

    return;
}

sub gen_var {
    $var_id++;
    return "\$$var_prefix$var_id$var_suffix";
}

sub replace_statement_node {
    my ($self, $node, $code) = @_;
    my $line_number = $node->last_token->logical_line_number + $self->{line};
    $node->insert_after($_->remove)
        for reverse PPI::Document->new(\"\n#line $line_number")->elements;
    $node->insert_after($_->remove)
        for reverse PPI::Document->new(\$code)->elements;
    $node->remove;
    return;
}

1;
