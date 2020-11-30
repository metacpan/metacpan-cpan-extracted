use strict;
use warnings;

package Text::Parser::Rule 1.000;

# ABSTRACT: Makes it possible to write AWK-style parsing rules for Text::Parser

use Moose;
use MooseX::StrictConstructor;
use Text::Parser::Error;
use Scalar::Util 'blessed', 'looks_like_number';
use String::Util ':all';
use List::Util qw(reduce any all none notall first
    max maxstr min minstr product sum sum0 pairs
    unpairs pairkeys pairvalues pairfirst
    pairgrep pairmap shuffle uniq uniqnum uniqstr
);
use Try::Tiny;


sub BUILD {
    my $self = shift;
    parser_exception("Rule created without required components")
        if not $self->_has_condition and not $self->_has_action;
    $self->action('return $0;') if not $self->_has_action;
    $self->_constr_condition    if not $self->_has_condition;
}

sub _constr_condition {
    my $self = shift;
    $self->condition(1);
    $self->_has_blank_condition(1);
}


sub clone {
    my ( $self, %opt ) = ( shift, @_ );
    return _clone_another_rule( \%opt, $self->_construct_from_rule(@_) );
}

sub _construct_from_rule {
    my ( $self, %opt ) = ( shift, @_ );
    my %const = ();
    $const{if} = $opt{if} if exists $opt{if};
    $const{if} = $self->condition
        if not( exists $const{if} )
        and not( $self->_has_blank_condition );
    $const{do} = $opt{do} if exists $opt{do};
    $const{do} = $self->action
        if not( exists $const{do} );
    $const{dont_record}
        = exists $opt{dont_record} ? $opt{dont_record} : $self->dont_record;
    $const{continue_to_next}
        = exists $opt{continue_to_next}
        ? $opt{continue_to_next}
        : $self->continue_to_next;
    return \%const;
}

sub _clone_another_rule {
    my ( $opt, $const ) = ( shift, shift );
    my $r = Text::Parser::Rule->new($const);
    $r->add_precondition( $opt->{add_precondition} )
        if exists $opt->{add_precondition};
    return $r;
}


has condition => (
    is        => 'rw',
    isa       => 'Str',
    predicate => '_has_condition',
    init_arg  => 'if',
    trigger   => \&_set_condition,
);

sub _set_condition {
    my $self = shift;
    return if ( $self->condition =~ /^\s*$/ );
    $self->_has_blank_condition(0);
    $self->_set_highest_nf;
    $self->_cond_sub_str( _gen_sub_str( $self->condition ) );
    $self->_cond_sub(
        _set_cond_sub( $self->condition, $self->_cond_sub_str ) );
}

has _has_blank_condition => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 1,
);

sub _set_highest_nf {
    my $self = shift;
    my $nf   = _get_min_req_fields( $self->_gen_joined_str );
    $self->_set_min_nf($nf);
}

sub _gen_joined_str {
    my $self = shift;
    my (@strs) = ();
    push @strs, $self->condition            if $self->_has_condition;
    push @strs, $self->action               if $self->_has_action;
    push @strs, $self->_join_preconds('; ') if not $self->_no_preconds;
    my $str = join '; ', @strs;
}

sub _get_min_req_fields {
    my $str = shift;
    my @indx
        = $str =~ /\$([0-9]+)|\$[{]([-][0-9]+)[}]|[$][{]([-]?[0-9]+)[+][}]/g;
    my @inds = sort { $b <=> $a } ( grep { defined $_ } @indx );
    return 0 if not @inds;
    ( $inds[0] >= -$inds[-1] ) ? $inds[0] : -$inds[-1];
}

my $SUB_BEGIN = 'sub {
    my ($self, $this) = (shift, shift);
    my $__ = $this->_stashed_vars;
    local $_ = $this->this_line;
    ';

my $SUB_END = '
}';

sub _gen_sub_str {
    my $str  = shift;
    my $anon = $SUB_BEGIN . _replace_awk_vars($str) . $SUB_END;
    return $anon;
}

sub _replace_awk_vars {
    local $_ = shift;
    _replace_positional_indicators();
    _replace_range_shortcut();
    _replace_exawk_vars() if m/[~][a-z_][a-z0-9_]+/i;
    return $_;
}

sub _replace_positional_indicators {
    s/\$0/\$this->this_line/g;
    s/\$[{]([-][0-9]+)[}]/\$this->field($1)/g;
    s/\$([0-9]+)/\$this->field($1-1)/g;
}

sub _replace_range_shortcut {
    s/\$[{]([-][0-9]+)[+][}]/\$this->join_range($1)/g;
    s/\$[{]([0-9]+)[+][}]/\$this->join_range($1-1)/g;
    s/\\\@[{]([-][0-9]+)[+][}]/[\$this->field_range($1)]/g;
    s/\\\@[{]([0-9]+)[+][}]/[\$this->field_range($1-1)]/g;
    s/\@[{]([-][0-9]+)[+][}]/\$this->field_range($1)/g;
    s/\@[{]([0-9]+)[+][}]/\$this->field_range($1-1)/g;
}

sub _replace_exawk_vars {
    my (@varnames) = _uniq( $_ =~ /[~]([a-z_][a-z0-9_]+)/ig );
    foreach my $var (@varnames) {
        my $v = '~' . $var;
        s/$v/\$__->{$var}/g;
    }
}

sub _uniq {
    my (%elem) = map { $_ => 1 } @_;
    return ( keys %elem );
}

has _cond_sub_str => (
    is       => 'rw',
    isa      => 'Str',
    init_arg => undef,
);

sub _set_cond_sub {
    my ( $rstr, $sub_str ) = @_;
    my $sub = eval $sub_str;
    parser_exception("Bad rule syntax $rstr: $@: $sub_str")
        if not defined $sub;
    return $sub;
}

has _cond_sub => (
    is       => 'rw',
    isa      => 'CodeRef',
    init_arg => undef,
);

has min_nf => (
    is       => 'ro',
    isa      => 'Num',
    traits   => ['Number'],
    init_arg => undef,
    default  => 0,
    lazy     => 1,
    handles  => { _set_min_nf => 'set', }
);


has action => (
    is        => 'rw',
    isa       => 'Str',
    init_arg  => 'do',
    predicate => '_has_action',
    trigger   => \&_set_action,
);

sub _set_action {
    my $self = shift;
    $self->_set_highest_nf;
    $self->_act_sub_str( _gen_sub_str( $self->action ) );
    $self->_act_sub( _set_cond_sub( $self->action, $self->_act_sub_str ) );
}

has _act_sub => (
    is       => 'rw',
    isa      => 'CodeRef',
    init_arg => undef,
);

has _act_sub_str => (
    is       => 'rw',
    isa      => 'Str',
    init_arg => undef,
);


has dont_record => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    lazy    => 1,
    trigger => \&_check_continue_to_next,
);

sub _check_continue_to_next {
    my $self = shift;
    return if not $self->continue_to_next;
    parser_exception(
        "Rule cannot continue to next if action result is recorded")
        if not $self->dont_record;
}


has continue_to_next => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    lazy    => 1,
    trigger => \&_check_continue_to_next,
);


has _preconditions => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    init_arg => undef,
    default  => sub { [] },
    lazy     => 1,
    traits   => ['Array'],
    handles  => {
        _preconds        => 'elements',
        add_precondition => 'push',
        _join_preconds   => 'join',
        _get_precond     => 'get',
        _no_preconds     => 'is_empty',
    },
);

after add_precondition => sub {
    my $self = shift;
    $self->_set_highest_nf;
    my $str    = $self->_get_precond(-1);
    my $substr = _gen_sub_str($str);
    $self->_add_precond_substr($substr);
    $self->_add_precond_sub( _set_cond_sub( $str, $substr ) );
};

has _precondition_substrs => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    init_arg => undef,
    default  => sub { [] },
    lazy     => 1,
    traits   => ['Array'],
    handles  => {
        _precond_substrs    => 'elements',
        _add_precond_substr => 'push',
    }
);

has _precond_subroutines => (
    is       => 'ro',
    isa      => 'ArrayRef[CodeRef]',
    init_arg => undef,
    default  => sub { [] },
    lazy     => 1,
    traits   => ['Array'],
    handles  => {
        _precond_subs    => 'elements',
        _add_precond_sub => 'push',
    }
);


sub test {
    my $self = shift;
    return 0 if not _check_parser_arg(@_);
    my $parser = shift;
    return 0 if not $parser->auto_split;
    return $self->_test($parser);
}

sub _check_parser_arg {
    return 0 if not @_;
    my $parser = shift;
    return 0 if not defined blessed($parser);
    $parser->isa('Text::Parser');
}

sub _test {
    my ( $self, $parser ) = ( shift, shift );
    return 0 unless defined( $parser->this_line );
    return 0 if $parser->NF < $self->min_nf;
    return 0
        if not( $self->_no_preconds or $self->_test_preconditions($parser) );
    return 1 if $self->_has_blank_condition;
    return $self->_test_cond_sub($parser);
}

sub _test_preconditions {
    my ( $self, $parser ) = @_;
    foreach my $cond ( $self->_precond_subs ) {
        my $val = $cond->( $self, $parser );
        return 0 if not defined $val or not $val;
    }
    return 1;
}

sub _test_cond_sub {
    my ( $self, $parser ) = @_;
    my $cond = $self->_cond_sub;
    my $val  = $cond->( $self, $parser );
    defined $val and $val;
}


sub run {
    my $self = shift;
    parser_exception("Method run on rule was called without a parser object")
        if not _check_parser_arg(@_);
    return if not $_[0]->auto_split;
    push @_, 1 if @_ < 2;
    $self->_run(@_);
}

sub _run {
    my ( $self, $parser ) = ( shift, shift );
    return if nocontent( $self->action );
    my (@res) = $self->_call_act_sub( $parser, @_ );
    return if $self->dont_record;
    $parser->push_records(@res);
}

sub _call_act_sub {
    my ( $self, $parser, $test_line ) = @_;
    return if $test_line and not defined $parser->this_line;
    my $act = $self->_act_sub;
    return ( $act->( $self, $parser ) );
}

__PACKAGE__->meta->make_immutable;

no Moose;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Parser::Rule - Makes it possible to write AWK-style parsing rules for Text::Parser

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    use Text::Parser;

    my $parser = Text::Parser->new();
    $parser->add_rule(
        if               => '$1 eq "NAME:"',      # Some condition string
        do               => 'return $2;',         # Some action to do when condition is met
        dont_record      => 1,                    # Directive to not record
        continue_to_next => 1,                    # Directive to next rule till another rule
    );
    $parser->read(shift);

=head1 DESCRIPTION

This class is never used directly. Instead rules are created and managed in one of two ways:

=over 4

=item *

via the C<L<add_rule|Text::Parser/"add_rule">> method of L<Text::Parser>

=item *

using C<L<applies_rule|Text::Parser::RuleSpec/"applies_rule">> function from L<Text::Parser::RuleSpec>

=back

In both cases, the arguments are the same.

=head1 METHODS

=head2 condition

Read-write attribute accessor method. Returns a string with the condition string as supplied to the C<if> clause in the constructor.

    my $cond_str = $rule->condition();

Or modify the condition of a given rule:

    $rule->condition($new_condition);

=head2 action

Read-write accessor method for the C<do> clause of the rule. This is similar to the C<condition> accessor method.

    my $act_str = $rule->action;
    $rule->action($modified_action);

=head2 dont_record

Read-write boolean accessor method for the C<dont_record> attribute of the constructor.

    print "This rule will not record\n" if $rule->dont_record;

=head2 continue_to_next

Read-write boolean accessor method for the C<continue_to_next> attribute in the constructor.

    print "Continuing to the next rule\n" if $rule->continue_to_next;

=head2 add_precondition

Method that can be used to add more pre-conditions to a rule

    $rule->add_precondition('looks_like_number($1)');
    # Check if the first field on line is a number

When you call C<L<test|/"test">> on the rule, it tests all the pre-conditions and the regular condition. If any of them fail, the test returns a boolean false.

This method is very useful when you clone a rule.

=head2 test

Method called internally in L<Text::Parser>. Runs code in C<if> block.

    print "I will run the task of the rule\n" if $rule->test;

=head2 run

Method called internally in L<Text::Parser>. Runs code in C<do> block, and saves the result as a record depending on C<dont_record>.

    my $result = $rule->run();

=head1 CONSTRUCTOR

=head2 new

Instances of this class can be created using the C<new> constructor, but normally a user would never create a rule themselves:

    my $rule = Text::Parser::Rule->new(
        if               => '# some condition string', 
        do               => '# some task rule', 
            # At least one of the above two clauses must be specified
            # When not specified, if clause defaults to 1
            # When not specified, do clause defaults to 'return $_;'
        dont_record      => 1, # default: 0
        continue_to_next => 1, # default: 0
    );

=head2 clone

You can clone a rule and construct another rule from it.

    $new_rule = $rule->clone();
     # Just creates a clone of $rule.

The above is not particularly useful as it just creates a copy of the same rule. In the below example, we demonstrate that any of the four main attributes of a rule could be changed while creating a clone. For example:

    $rule = Text::Parser::Rule->new(
        if               => '# some condition',
    );
    $new_rule = $rule->clone(
        # all of these are optional
        do               => '# modify original action', 
        dont_record      => 1, 
        continue_to_next => 1,
    );

You could also change the C<if> clause above, but you could also add a pre-condition at the time of creating C<$new_rule> without affecting C<$rule> itself:

    $new_rule = $rule->clone(
        add_precondition => '# another condition',
        # ...
    );

The C<clone> method is just another way to create a rule. It just uses an existing rule as a seed.

=head1 SEE ALSO

=over 4

=item *

L<Text::Parser>

=item *

L<"The AWK Programming Language"|https://books.google.com/books?id=53ueQgAACAAJ&dq=The+AWK+Programming+Language&hl=en&sa=X&ei=LXxXVfq0GMOSsAWrpoC4Bg&ved=0CCYQ6AEwAA> by Alfred V. Aho, Brian W. Kernighan, and Peter J. Weinberger, Addison-Wesley, 1988. ISBN 0-201-07981-X

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://github.com/balajirama/Text-Parser/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Balaji Ramasubramanian <balajiram@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2019 by Balaji Ramasubramanian.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
