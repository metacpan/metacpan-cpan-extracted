use strict;
use warnings;

package Text::Parser::Rule 0.925;

# ABSTRACT: Makes it possible to write AWK-style parsing rules for Text::Parser

use Moose;
use Text::Parser::Errors;
use Scalar::Util 'blessed', 'looks_like_number';
use String::Util ':all';
use String::Util::Match 'match_array_or_regex';
use String::Util::Range 'convert_sequence_to_range';
use String::Index qw(cindex ncindex crindex ncrindex);
use List::Util qw(max maxstr min minstr product sum0
    uniq pairs unpairs pairkeys
    pairvalues pairfirst pairgrep pairmap);


has condition => (
    is        => 'rw',
    isa       => 'Str',
    predicate => '_has_condition',
    init_arg  => 'if',
    trigger   => \&_set_condition,
);

sub _set_condition {
    my $self = shift;
    $self->_set_highest_nf;
    $self->_cond_sub_str( _gen_sub_str( $self->condition ) );
    $self->_cond_sub(
        _set_cond_sub( $self->condition, $self->_cond_sub_str ) );
}

sub _get_min_req_fields {
    my $str = shift;
    my @indx
        = $str =~ /\$([0-9]+)|\$[{]([-][0-9]+)[}]|[$@][{]([-]?[0-9]+)[+][}]/g;
    my @inds = sort { $b <=> $a } ( grep { defined $_ } @indx );
    return 0 if not @inds;
    ( $inds[0] >= -$inds[-1] ) ? $inds[0] : -$inds[-1];
}

my $SUB_BEGIN = 'sub {
    my $this = shift;
    my $__ = $this->_ExAWK_symbol_table;
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
    my (@varnames) = uniq( $_ =~ /[~]([a-z_][a-z0-9_]+)/ig );
    foreach my $var (@varnames) {
        my $v = '~' . $var;
        s/$v/\$__->{$var}/g;
    }
}

has _cond_sub_str => (
    is       => 'rw',
    isa      => 'Str',
    init_arg => undef,
);

sub _set_cond_sub {
    my ( $rstr, $sub_str ) = @_;
    my $sub = eval $sub_str;
    _throw_bad_cond( $rstr, $sub_str, $@ ) if not defined $sub;
    return $sub;
}

sub _throw_bad_cond {
    my ( $code, $sub_str, $msg ) = @_;
    die bad_rule_syntax(
        code       => $code,
        msg        => $msg,
        subroutine => $sub_str,
    );
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
    die illegal_rule_cont if not $self->dont_record;
}


has continue_to_next => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    lazy    => 1,
    trigger => \&_check_continue_to_next,
);


sub BUILD {
    my $self = shift;
    die illegal_rule_no_if_no_act
        if not $self->_has_condition and not $self->_has_action;
    $self->action('return $0;') if not $self->_has_action;
    $self->condition(1)         if not $self->_has_condition;
}


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
    return 0 if not $parser->auto_split or $parser->NF < $self->min_nf;
    return 0 if not $self->_test_preconditions($parser);
    return $self->_test_cond_sub($parser);
}

sub _check_parser_arg {
    return 0 if not @_;
    my $parser = shift;
    return 0 if not defined blessed($parser);
    $parser->isa('Text::Parser');
}

sub _test_preconditions {
    my ( $self, $parser ) = @_;
    foreach my $cond ( $self->_precond_subs ) {
        my $val = $cond->($parser);
        return 0 if not defined $val or not $val;
    }
    return 1;
}

sub _test_cond_sub {
    my ( $self, $parser ) = @_;
    my $cond = $self->_cond_sub;
    return 0 if not defined $parser->this_line;
    my $val = $cond->($parser);
    defined $val and $val;
}


sub run {
    my $self = shift;
    die rule_run_improperly if not _check_parser_arg(@_);
    return if nocontent( $self->action ) or not $_[0]->auto_split;
    push @_, 1 if @_ == 1;
    my (@res) = $self->_call_act_sub(@_);
    return if $self->dont_record;
    $_[0]->push_records(@res);
}

sub _call_act_sub {
    my ( $self, $parser, $test_line ) = @_;
    return if $test_line and not defined $parser->this_line;
    my $act = $self->_act_sub;
    return ( $act->($parser) );
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

version 0.925

=head1 SYNOPSIS

Users should not use this class directly to create and run rules. See L<Text::Parser::Manual::ExtendedAWKSyntax> for instructions on creating rules in a class. But the example below shows the way this class works for those that intend to improve the class.

    use Text::Parser::Rule;
    use Text::Parser;               # To demonstrate use with Text::Parser
    use Data::Dumper 'Dumper';      # To print any records

    my $rule = Text::Parser::Rule->new( if => '$1 eq "NAME:"', do => '${2+}' );

    # Must have auto_split attribute set - this is automatically done by
    # the add_rule method of Text::Parser
    my $parser = Text::Parser->new(auto_split => 1);

    # Example of how internally the $parser would run the $rule
    # This code below won't really run any rules because rules
    # have to be applied when the $parser->read() method is called
    # and not outside of that
    $rule->run($parser) if $rule->test($parser);
    print "Continuing to next rule..." if $rule->continue_to_next;

=head1 CONSTRUCTOR

=head2 new

Takes optional attributes described in L<ATTRIBUTES|/ATTRIBUTES> section.

    my $rule = Text::Parser::Rule->new(
        condition => '$1 eq "NAME:"',   # Some condition string
        action => 'return $2;',         # Some action to do when condition is met
        dont_record => 1,               # Directive to not record
        continue_to_next => 1,          # Directive to next rule till another rule
                                        # passes test condition
    );

=head1 ATTRIBUTES

The attributes below may be used as options to C<new> constructor. Note that in some cases, the accessor method for the attribute is differently named. Use the attribute name in the constructor and accessor as a method.

=head2 condition

Read-write attribute. Set in the constructor with C<if> key. Must be string which after transformation must C<eval> successfully without compilation errors.

    my $rule = Text::Parser::Rule->new( if => 'm//' );
    print $rule->action, "\n";           # m//
    $rule->action('m/something/');
    print $rule->action, "\n";           @ m/something/

During a call to C<L<test|/test>> method, this C<condition> is C<eval>uated and the result is returned as a boolean for further decision-making.

=head2 min_nf

Read-only attribute. Gets adjusted automatically.

    print "Rule requires a minimum of ", $rule->min_nf, " fields on the line.\n";

=head2 action

Read-write attribute. Set in the constructor with C<do> key. Must be string which after transformation must C<eval> successfully without compilation errors.

    my $rule = Text::Parser->new( do => '' );
    print $rule->action, "\n";        # :nothing:
    $rule->action('return $1');
    print $rule->action, "\n";        # return $1

The C<L<action|/action>> is executed during a call to C<run> when C<condition> (and all preconditions) is true. The return value of the C<eval>uated C<action> is used or discarded based on the C<dont_record> attribute.

=head2 dont_record

Boolean indicating if return value of the C<action> (when transformed and C<eval>uated) should be stored in the parser as a record.

    print "Will not save records\n" if $rule->dont_record;

The attribute is used in C<L<run|/run>> method. The results of the C<eval>uated C<action> are recorded in the object passed to C<run>. But when this attribute is set to true, then results are not recorded.

=head2 continue_to_next

Takes a boolean value. This can be set true only for rules with C<dont_record> attribute set to a true value. This attribute indicates that the rule will proceed to the next rule until some rule passes the C<L<test|/test>>. It is easiest to understand the use of this if you imagine a series of rules to test and execute in sequence:

    # This code is actually used in Text::Parser
    # to run through the rules specified
    foreach my $rule (@rules) {
        next if not $rule->test($parser);
        $rule->run($parser);
        last if not $rule->continue_to_next;
    }

=head1 METHODS

=head2 add_precondition

Takes a list of rule strings that are similar to the C<condition> string. For example:

    $rule->add_precondition(
        '$2 !~ /^ln/', 
        'looks_like_number($3)', 
    );

During the call to C<L<test|/test>>, these preconditions and the C<condition> will all be combined in the C<and> operation. That means, all the preconditions must be satisfied, and then the C<condition> must be satisfied. If any of them C<eval>uates to a false boolean, C<test> will return false.

=head2 test

Takes one argument that must be a C<Text::Parser>. Returns a boolean value may be used to decide to call the C<run> method.

If all preconditions and C<condition> C<eval>uate to a boolean true, then C<test> returns true.

    my $parser = Text::Parser->new(auto_split => 1);
    $rule->test($parser);

The method will always return a boolean false if the C<Text::Parser> object passed does not have the C<auto_split> attribute on.

=head2 run

Takes one argument that must be a C<Text::Parser>, and one optional argument which can be C<0> or C<1>. The default for this optional argument is C<1>. The C<0> value is used when calling a special kind of rule that doesn't need to check for valid current line (mainly useful for C<BEGIN> and C<END> rules). Has no return value.

    my $parser = Text::Parser->new(auto_split => 1);
    $rule->run($parser);
    $rule->run($parser, 'no_line');

Runs the C<eval>uated C<action>. If C<dont_record> is false, the return value of the C<action> is recorded in C<$parser>. Otherwise, it is ignored.

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
