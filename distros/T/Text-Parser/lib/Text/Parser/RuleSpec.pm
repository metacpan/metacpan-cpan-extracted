## Please see file perltidy.ERR
use strict;
use warnings;

package Text::Parser::RuleSpec 1.000;

# ABSTRACT: Syntax sugar for rule specification while subclassing Text::Parser or derivatives


use Moose;
use Moose::Exporter;
use MooseX::ClassAttribute;
use Text::Parser::Error;
use Text::Parser::Rule;
use List::MoreUtils qw(before_incl after_incl);

Moose::Exporter->setup_import_methods(
    with_meta => [
        'applies_rule',              'unwraps_lines_using',
        'disables_superclass_rules', 'applies_cloned_rule',
    ],
    as_is => ['_check_custom_unwrap_args'],
    also  => 'Moose'
);

class_has _all_rules => (
    is      => 'rw',
    isa     => 'HashRef[Text::Parser::Rule]',
    lazy    => 1,
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        _add_new_rule     => 'set',
        is_known_rule     => 'exists',
        class_rule_object => 'get',
    },
);

class_has _class_rule_order => (
    is      => 'rw',
    isa     => 'HashRef[ArrayRef[Str]]',
    lazy    => 1,
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        _class_has_rules      => 'exists',
        __cls_rule_order      => 'get',
        _set_class_rule_order => 'set',
    }
);

class_has _class_rules_in_order => (
    is      => 'rw',
    isa     => 'HashRef[ArrayRef[Text::Parser::Rule]]',
    lazy    => 1,
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        _class_rules        => 'get',
        _set_rules_of_class => 'set',
    },
);


sub class_has_rules {
    my ( $this_cls, $cls ) = ( shift, shift );
    return 0 if not defined $cls;
    return 0 if not $this_cls->_class_has_rules($cls);
    return $this_cls->class_rule_order($cls);
}


sub class_rule_order {
    my ( $class, $cls ) = @_;
    return () if not defined $cls;
    $class->_class_has_rules($cls) ? @{ $class->__cls_rule_order($cls) } : ();
}


sub class_rules {
    my ( $class, $cls ) = @_;
    return () if not $class->class_has_rules($cls);
    @{ $class->_class_rules($cls) };
}



sub populate_class_rules {
    my ( $class, $cls ) = @_;
    return if not defined $cls or not $class->_class_has_rules($cls);
    my @ord = $class->class_rule_order($cls);
    $class->_set_rules_of_class(
        $cls => [ map { $class->class_rule_object($_) } @ord ] );
}


sub applies_rule {
    my ( $meta, $name ) = ( shift, shift );
    _first_things_on_applies_rule( $meta, $name, @_ );
    _register_rule( _full_rule_name( $meta, $name ), @_ );
    _set_correct_rule_order( $meta, $name, @_ );
}

sub _first_things_on_applies_rule {
    my ( $meta, $name ) = ( shift, shift );
    _excepts_apply_rule( $meta, $name, @_ );
    _set_default_of_attributes( $meta, auto_split => 1 );
}

sub _full_rule_name {
    my ( $meta, $name ) = ( shift, shift );
    return $meta->name . '/' . $name;
}

sub _excepts_apply_rule {
    my ( $meta, $name ) = ( shift, shift );
    _rulespec_cant_be_in_main( $meta, $name, 'applies_rule' );
    _rule_must_have_name( $meta, $name );
    _check_args_hash_stuff( $meta, "applies_rule $name", @_ );
}

sub _rulespec_cant_be_in_main {
    my ( $meta, $name, $funcname ) = ( shift, shift, shift );
    my $follow = defined $name ? ": $name" : '.';
    parser_exception("$funcname cannot be called in main$follow")
        if $meta->name eq 'main';
}

my %rule_options = (
    if               => 1,
    do               => 1,
    dont_record      => 1,
    continue_to_next => 1,
    before           => 1,
    after            => 1,
);

sub _rule_must_have_name {
    my ( $meta, $name ) = ( shift, shift );
    parser_exception("applies_rule requires rule name argument")
        if not defined $name
        or ( '' ne ref($name) )
        or ( exists $rule_options{$name} );
}

sub _check_args_hash_stuff {
    my ( $meta, $funccall ) = ( shift, shift );
    my (%opt) = _check_arg_is_hash( $funccall, @_ );
    _if_empty_prepopulate_rules_from_superclass($meta);
    _check_location_args( $meta, $funccall, %opt )
        if _has_location_opts(%opt);
}

sub _has_location_opts {
    my (%opt) = @_;
    exists $opt{before} or exists $opt{after};
}

sub _check_arg_is_hash {
    my $funccall = shift;
    parser_exception(
        "$funccall must be followed by a hash. See documentation.")
        if not @_
        or ( scalar(@_) % 2 );
    return @_;
}

sub _check_location_args {
    my ( $meta, $name, %opt ) = ( shift, shift, @_ );
    parser_exception(
        "\'$name\' call can have \'before\' or \'after\'; not both.")
        if exists $opt{before} and exists $opt{after};
    my $loc = exists $opt{before} ? 'before' : 'after';
    my ( $cls, $rule ) = split /\//, $opt{$loc}, 2;
    parser_exception(
        "Clause $loc must follow format <classname>/<rulename>: \'$name\'")
        if not defined $rule;
    parser_exception("Unknown rule $opt{$loc} in clause $loc: \'$name\'")
        if not Text::Parser::RuleSpec->is_known_rule( $opt{$loc} );
    my (@r) = Text::Parser::RuleSpec->class_rule_order( $meta->name );
    my $is_super_rule = grep { $_ eq $opt{$loc} } @r;
    parser_exception(
        "Use \'$loc\' clause only with superclass rules ; not this class: \'$name\'"
    ) if $cls eq $meta->name or not $is_super_rule;
}

sub _register_rule {
    my $key = shift;
    parser_exception("name rules uniquely: $key")
        if Text::Parser::RuleSpec->is_known_rule($key);
    my %opts = _get_rule_opts_only(@_);
    my $rule = Text::Parser::Rule->new(%opts);
    Text::Parser::RuleSpec->_add_new_rule( $key => $rule );
}

sub _get_rule_opts_only {
    my (%opt) = @_;
    delete $opt{before} if exists $opt{before};
    delete $opt{after}  if exists $opt{after};
    return (%opt);
}

sub _set_default_of_attributes {
    my ( $meta, %val ) = @_;
    while ( my ( $k, $v ) = ( each %val ) ) {
        _inherit_set_default_mk_ro( $meta, $k, $v )
            if not defined $meta->get_attribute($k);
    }
}

sub _inherit_set_default_mk_ro {
    my ( $meta, $attr, $def ) = ( shift, shift, shift );
    my $old = $meta->find_attribute_by_name($attr);
    my $new = $old->clone_and_inherit_options( default => $def, is => 'ro' );
    $meta->add_attribute($new);
}

sub _set_correct_rule_order {
    my ( $meta, $rule_name ) = ( shift, shift );
    my $rname = _full_rule_name( $meta, $rule_name );
    return _push_to_class_rules( $meta->name, $rname )
        if not _has_location_opts(@_);
    _insert_rule_in_order( $meta->name, $rname, @_ );
}

my %INSERT_RULE_FUNC = (
    before => \&_ins_before_rule,
    after  => \&_ins_after_rule,
);

sub _insert_rule_in_order {
    my ( $cls, $rname, %opt ) = ( shift, shift, @_ );
    my $loc = exists $opt{before} ? 'before' : 'after';
    $INSERT_RULE_FUNC{$loc}->( $cls, $opt{$loc}, $rname );
    Text::Parser::RuleSpec->populate_class_rules($cls);
}

sub _ins_before_rule {
    my ( $cls, $before, $rname ) = ( shift, shift, shift );
    my (@ord)  = Text::Parser::RuleSpec->class_rule_order($cls);
    my (@ord1) = before_incl { $_ eq $before } @ord;
    my (@ord2) = after_incl { $_ eq $before } @ord;
    pop @ord1;
    Text::Parser::RuleSpec->_set_class_rule_order(
        $cls => [ @ord1, $rname, @ord2 ] );
}

sub _ins_after_rule {
    my ( $cls, $after, $rname ) = ( shift, shift, shift );
    my (@ord)  = Text::Parser::RuleSpec->class_rule_order($cls);
    my (@ord1) = before_incl { $_ eq $after } @ord;
    my (@ord2) = after_incl { $_ eq $after } @ord;
    shift @ord2;
    Text::Parser::RuleSpec->_set_class_rule_order(
        $cls => [ @ord1, $rname, @ord2 ] );
}

sub _if_empty_prepopulate_rules_from_superclass {
    my ( $meta, $cls ) = ( shift, 'Text::Parser::RuleSpec' );
    my @ro = map { $cls->class_rule_order($_) } ( $meta->superclasses );
    $cls->_set_class_rule_order( $meta->name => \@ro )
        if not $cls->_class_has_rules( $meta->name );
}

sub _push_to_class_rules {
    my ( $class, $cls, $rulename ) = ( 'Text::Parser::RuleSpec', @_ );
    my @ord = $class->class_rule_order($cls);
    push @ord, $rulename;
    $class->_set_class_rule_order( $cls => \@ord );
    $class->populate_class_rules($cls);
}


sub applies_cloned_rule {
    my ( $meta, $orule ) = ( shift, shift );
    _first_things_on_applies_cloned_rule( $meta, $orule, @_ );
    my $nrule = _gen_new_rule_name_from( $meta, $orule );
    _register_cloned_rule( _full_rule_name( $meta, $nrule ),
        _qualified_rulename( $orule, $meta ), @_ );
    _set_correct_rule_order( $meta, $nrule, @_ );
}

sub _first_things_on_applies_cloned_rule {
    my ( $meta, $name ) = ( shift, shift );
    _excepts_apply_cloned_rule( $meta, $name, @_ );
    _set_default_of_attributes( $meta, auto_split => 1 );
}

sub _excepts_apply_cloned_rule {
    my ( $meta, $name ) = ( shift, shift );
    _rulespec_cant_be_in_main( $meta, $name, 'applies_cloned_rule' );
    _must_have_named_super( $meta, $name );
    _check_args_hash_stuff( $meta, "applies_cloned_rule $name", @_ );
    parser_exception("$name is not an existing rule ; can\'t clone it")
        if not _is_existing_rule( $name, $meta );
}

my %clone_options = ( %rule_options, add_precondition => 1, );

sub _must_have_named_super {
    my ( $meta, $name ) = ( shift, shift );
    parser_exception("applies_cloned_rule requires original rule name")
        if not defined $name
        or ( '' ne ref($name) )
        or ( exists $clone_options{$name} );
}

sub _is_existing_rule {
    my ( $rname, $meta ) = ( shift, shift );
    return 1 if Text::Parser::RuleSpec->is_known_rule($rname);
    return 0 if $rname =~ /\//;
    return Text::Parser::RuleSpec->is_known_rule(
        $meta->name . '/' . $rname );
}

sub _qualified_rulename {
    my ( $r, $meta ) = ( shift, shift );
    return $meta->name . '/' . $r
        if not Text::Parser::RuleSpec->is_known_rule($r);
    return $r;
}

sub _gen_new_rule_name_from {
    my ( $meta, $oname ) = ( shift, shift );
    my ( $cls,  $rname ) = split( /\//, $oname, 2 );
    $rname = $cls if not defined $rname;
    my $nname = $meta->name . '/' . $rname;
    return $rname if not Text::Parser::RuleSpec->is_known_rule($nname);
    my $incr = 2;
    $incr++ while Text::Parser::RuleSpec->is_known_rule("$nname\@$incr");
    return "$rname\@$incr";
}

sub _register_cloned_rule {
    my ( $key, $orule ) = ( shift, shift );
    my %opts = _get_rule_opts_only(@_);
    my $o    = Text::Parser::RuleSpec->class_rule_object($orule);
    my $rule = $o->clone(%opts);
    Text::Parser::RuleSpec->_add_new_rule( $key => $rule );
}


sub disables_superclass_rules {
    my $meta = shift;
    _rulespec_cant_be_in_main( $meta, undef, 'disables_superclass_rules' );
    _check_disable_rules_args( $meta->name, @_ );
    _find_and_remove_superclass_rules( $meta, @_ );
}

sub _check_disable_rules_args {
    my $cls = shift;
    parser_exception(
        "No arguments specified in call to disable_superclass_rules")
        if not @_;
    foreach my $a (@_) {
        _test_rule_type_and_val( $cls, $a );
    }
}

my %disable_arg_types = ( '' => 1, 'Regexp' => 1, 'CODE' => 1 );

sub _test_rule_type_and_val {
    my $type_a = ref( $_[1] );
    parser_exception(
        "Rules must be selected by regular expressions or a code")
        if not exists $disable_arg_types{$type_a};
    _test_rule_string_val(@_) if $type_a eq '';
}

sub _test_rule_string_val {
    my ( $cls, $a ) = ( shift, shift );
    parser_exception(
        "disable_superclass_rule called with $a ; must be in format <superclass>/<rulename>"
    ) if $a !~ /\//;
    my @c = split /\//, $a, 2;
    parser_exception("Cannot disable rules of same class") if $c[0] eq $cls;
}

sub _find_and_remove_superclass_rules {
    my $meta = shift;
    _if_empty_prepopulate_rules_from_superclass($meta);
    my @ord = _filtered_rules( $meta->name, @_ );
    Text::Parser::RuleSpec->_set_class_rule_order( $meta->name => \@ord );
    Text::Parser::RuleSpec->populate_class_rules( $meta->name );
}

sub _filtered_rules {
    my $cls = shift;
    local $_;
    map { _is_to_be_filtered( $_, @_ ) ? () : $_ }
        ( Text::Parser::RuleSpec->class_rule_order($cls) );
}

my %test_for_filter_type = (
    ''       => sub { $_[0] eq $_[1]; },
    'Regexp' => sub { $_[0] =~ $_[1]; },
    'CODE'   => sub { $_[1]->( $_[0] ); },
);

sub _is_to_be_filtered {
    my $r = shift;
    foreach my $p (@_) {
        my $t = ref $p;
        return 1 if $test_for_filter_type{$t}->( $r, $p );
    }
    return 0;
}


sub unwraps_lines_using {
    my $meta = shift;
    _rulespec_cant_be_in_main( $meta, undef, 'unwraps_lines_using' );
    my ( $is_wr, $un_wr ) = _check_custom_unwrap_args(@_);
    _set_lws_and_routines( $meta, $is_wr, $un_wr );
}

sub _check_custom_unwrap_args {
    parser_exception( "Needs exactly 4 arguments ; " . scalar(@_) . " given" )
        if @_ != 4;
    _test_fields_unwrap_rtn(@_);
    my (%opt) = @_;
    return ( $opt{is_wrapped}, $opt{unwrap_routine} );
}

sub _test_fields_unwrap_rtn {
    my (%opt) = (@_);
    parser_exception(
        "unwraps_lines_using must have keys: is_wrapped, unwrap_routine")
        if not( exists $opt{is_wrapped} and exists $opt{unwrap_routine} );
    _is_arg_a_code( $_, %opt ) for (qw(is_wrapped unwrap_routine));
}

sub _is_arg_a_code {
    my ( $arg, %opt ) = (@_);
    parser_exception(
        "$arg in call to unwraps_lines_using must be code reference")
        if 'CODE' ne ref( $opt{$arg} );
}

sub _set_lws_and_routines {
    my ( $meta, $is_wr, $unwr ) = @_;
    _set_default_of_attributes( $meta, line_wrap_style => 'custom' );
    _set_default_of_attributes( $meta, _is_wrapped     => sub { $is_wr; } );
    _set_default_of_attributes( $meta, _unwrap_routine => sub { $unwr; } );
}


__PACKAGE__->meta->make_immutable;

no Moose;
no MooseX::ClassAttribute;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Parser::RuleSpec - Syntax sugar for rule specification while subclassing Text::Parser or derivatives

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    package MyFavorite::Parser;

    use Text::Parser::RuleSpec;
    extends 'Text::Parser';

    has '+multiline_type'  => (default => 'join_next');

    unwraps_lines_using (
        is_wrapped     => sub {
            my $self = shift;
            $_ = shift;
            chomp;
            m/\s+[~]\s*$/;
        }, 
        unwrap_routine => sub {
            my ($self, $last, $current) = @_;
            chomp $last;
            $last =~ s/\s+[~]\s*$//g;
            "$last $current";
        }, 
    );

    applies_rule get_emails => (
        if => '$1 eq "EMAIL:"', 
        do => '$2;'
    );

    package main;

    my $parser = MyFavorite::Parser->new();
    $parser->read('/path/to/email_lists.txt');
    my (@emails) = $parser->get_records();
    print "Here are all the emails from the file: @emails\n";

=head1 DESCRIPTION

=head2 Primary usage

This class enables users to create their own parser classes for a known text file format, and facilitates code-sharing across multiple variants of the same basic text format. The basic steps are as follows:

    package MyFavorite::Parser;
    use Text::Parser::RuleSpec;
    extends 'Text::Parser';

That's it! This is the bare-minimum required to make your own text parser. But it is not particularly useful at this point without any rules of its own.

    applies_rule comment_char => (
        if          => '$1 =~ /^#/;', 
        dont_record => 1, 
    );

This above rule ignores all comment lines and is added to C<MyFavorite::Parser> class. So now when you create an instance of C<MyFavorite::Parser>, it would automatically run this rule when you call C<L<read|Text::Parser/read>>.

We can preset any attributes for this parser class using the familiar L<Moose> functions. Here is an example:

    has '+line_wrap_style' => (
        default => 'trailing_backslash', 
        is      => 'ro', 
    );

    has '+auto_trim' => (
        default => 'b', 
        is      => 'ro', 
    );

=head2 Using attributes for storage

Sometimes, you may want to store the parsed information in attributes, instead of records. So for example:

    has current_section => (
        is      => 'rw', 
        isa     => 'Str|Undef', 
        default => undef, 
        lazy    => 1, 
    );

    has _num_lines_by_section => (
        is      => 'rw', 
        isa     => 'HashRef[Int]', 
        default => sub { {}; }, 
        lazy    => 1, 
        handles => {
            num_lines      => 'get', 
            _set_num_lines => 'set', 
        }
    );

    applies_rule inc_section_num_lines => (
        if          => '$1 ne "SECTION"', 
        do          => 'my $sec = $this->current_section;
                        my $n = $this->num_lines($sec); 
                        $this->_set_num_lines($sec => $n+1);', 
        dont_record => 1, 
    );

    applies_rule get_section_name => (
        if          => '$1 eq "SECTION"', 
        do          => '$this->current_section($2); $this->_set_num_lines($2 => 0);', 
        dont_record => 1, 
    );

In the above example, you can see how the section name we get from one rule is used in a different rule.

=head2 Inheriting rules in subclasses

We can further subclass a class that C<extends> L<Text::Parser>. Inheriting the rules of the superclass is automatic:

    package MyParser1;
    use Text::Parser::RuleSpec;

    extends 'Text::Parser';

    applies_rule rule1 => (
        do => '# something', 
    );

    package MyParser2;
    use Text::Parser::RuleSpec;

    extends 'MyParser1';

    applies_rule rule1 => (
        do => '# something else', 
    );

Now, C<MyParser2> contains two rules: C<MyParser1/rule1> and C<MyParser2/rule1>. Note that both the rules in both classes are called C<rule1> and both will be executed. By default, rules of superclasses will be run before rules in the subclass. The subclass can change this order by explicitly stating that its own C<rule1> is run C<before> the C<rule1> of C<MyParser1>:

    package MyParser2;
    use Text::Parser::RuleSpec;

    extends 'MyParser1';

    applies_rule rule1 => (
        do     => '# something else', 
        before => 'MyParser1/rule1', 
    );

A subclass may choose to disable any superclass rules:

    package MyParser3;
    use Text::Parser::RuleSpec;

    extends 'MyParser2';

    disables_superclass_rules qr/^MyParser1/;  # disables all rules from MyParser1 class

Or to clone a rule from either the same class, a superclass, or even from some other random class.

    package ClonerParser;
    use Text::Parser::RuleSpec;

    use Some::Parser;  # contains rules: "heading", "section"
    extends 'MyParser2';

    applies_rule my_own_rule => (
        if    => '# check something', 
        do    => '# collect some data', 
        after => 'MyParser2/rule1', 
    );

    applies_cloned_rule 'MyParser2/rule1' => (
        add_precondition => '# Additional condition', 
        do               => '# Optionally change the action', 
        # prepend_action => '# Or just prepend something', 
        # append_action  => '# Or append something', 
        after            => 'MyParser1/rule1', 
    );

Imagine this situation: Programmer A writes a text parser for a text format syntax SYNT1, and programmer B notices that the text format he wishes to parse (SYNT2) is similar, except for a few differences. Instead of having to re-write the code from scratch, he can reuse the code from programmer A and modify it exactly as needed. This is especially useful when syntaxes many different text formats are very similar.

=head1 METHODS

There is no constructor for this module. You cannot create an instance of C<Text::Parser::RuleSpec>. Therefore, all methods here can be called on the C<Text::Parser::RuleSpec> directly.

=head2 class_has_rules

Takes parser class name and returns a boolean representing if that class has any rules or not. Returns boolean true if the class has any rules, and a boolean false otherwise.

    print "There are no class rules for MyFavorite::Parser.\n"
        if not Text::Parser::RuleSpec->class_has_rules('MyFavorite::Parser');

=head2 class_rule_order

Takes a single string argument and returns the ordered list of rule names for the class.

    my (@order) = Text::Parser::RuleSpec->class_rule_order('MyFavorite::Parser');

=head2 class_rule_object

This takes a single string argument with the fully qualified rule name, and returns the actual rule object identified by that name.

    my $rule = Text::Parser::RuleSpec->class_rule_object('MyFavorite::Parser/rule1');

=head2 class_rules

Takes a single string argument and returns the actual rule objects of the given class name. This is a shortcut to first running C<class_rule_order> and then running C<class_rule_object> on each one of them.

    my (@rules) = Text::Parser::RuleSpec->class_rules('MyFavorite::Parser');

=head2 is_known_rule

Takes a string argument expected to be fully-qualified name of a rule. Returns a boolean that indicates if such a rule was ever compiled. The fully-qualified name of a rule is of the form C<Some::Class/rule_name>. Any suffixes like C<@2> or C<@3> should be included to check the existence of any cloned rules.

    print "Some::Parser::Class/some_rule is a rule\n"
        if Text::Parser::RuleSpec->is_known_rule('Some::Parser::Class/some_rule');

=head2 populate_class_rules

Takes a parser class name as string argument. It populates the class rules according to the latest order of rules.

    Text::Parser::RuleSpec->populate_class_rules('MyFavorite::Parser');

=head1 FUNCTIONS

The following methods are exported into the namespace of your class by default, and may only be called outside the C<main> namespace.

=head2 applies_rule

Takes one mandatory string argument - a rule name - followed by the options to create a rule. These are the same as the arguments to the C<L<add_rule|Text::Parser/"add_rule">> method of L<Text::Parser> class. Returns nothing. Exceptions will be thrown if any of the required arguments are not provided.

    applies_rule print_emails => (
        if               => '$1 eq "EMAIL:"', 
        do               => 'print $2;', 
        dont_record      => 1, 
        continue_to_next => 1, 
    );

The above call to create a rule C<print_emails> in your class C<MyFavorite::Parser>, will save the rule as C<MyFavorite::Parser/print_emails>. So if you want to clone it in sub-classes or want to insert a rule before or after that in a sub-class, then this is the way to reference the rule.

Optionally, one may provide one of C<before> or C<after> clauses to specify when this rule is to be executed.

    applies_rule check_line_syntax => (
        if     => '$1 ne "SECTION"', 
        do     => '$this->check_syntax($this->current_section, $_);', 
        before => 'Parent::Parser/add_line_to_data_struct', 
    );

The above rule will apply C<>

Exceptions will be thrown if the C<before> or C<after> rule does not have a class name in it, or if it is the same as the current class, or if the rule is not among the inherited rules so far. Only one of C<before> or C<after> clauses may be provided.

=head2 applies_cloned_rule

Clones an existing rule to make a replica, but you can add options to change any parameters of the rule.

    applies_cloned_rule 'Some::SuperClass::Parser/some_rule' => (
        add_precondition => '1; # add some tests returning boolean', 
        before           => 'MayBe::Another::Superclass::Parser/some_other_rule',
            ## Or even 'Some::SuperClass::Parser/another_rule'
        do               => '## Change the do clause of original rule', 
    );

The first argument must be a string containing the rule name to be cloned. You may clone a superclass rule, or even a rule from another class that you have only C<use>d in your code, but are not actually inheriting (using C<extends>). You may even clone a rule from the present class if the rule has been defined already. If the rule name specified contains a class name, then the exact rule is cloned, modified according to other clauses, and inserted into the rule order. But if the rule name specified does not have a classname, then the function looks for a rule with that name in the current class, and clones that one.

You may use one of the C<before> or C<after> clauses just like in C<applies_rule>. You may use any of the other rule creation options like C<if>, C<do>, C<continue_to_next>, or C<dont_record>. And you may optionally also use the C<add_precondition> clause. In many cases, you may not need any of the rule-creation options at all and may use only C<add_precondition> or any one of C<before> or C<after> clauses. If you do use any of the rule-creating options like C<do> or C<if>, then it will change those fields of the cloned copy of the original rule.

Note that when you clone a rule, you do not change the original rule itself. You actually make a second copy and modify that. So you retain the original rule along with the clone.

The new cloned rule created is automatically renamed by C<applies_cloned_rule>. If a rule C<Some::Other::Class/my_rule_1> is cloned into your parser class C<MyFavorite::Parser>, then the clone is named C<MyFavorite::Parser/my_rule_1>. This way, the original rule is left unaffected. If such a name already exists, then the clone adds C<@2> suffix to the name, viz., C<MyFavorite::Parser/my_rule_1@2>. If that also exists, it will be called C<MyFavorite::Parser/my_rule_1@3>. And so on it goes on incrementing.

=head2 disables_superclass_rules

Takes a list of rule names, or regular expression patterns, or subroutine references to identify rules that are to be disabled. You cannot disable rules of the same class.

A string argument is expected to contain the full rule-name (including class name) in the format C<My::Parser::Class/my_rule>. The C</> (slash) separating the class name and rule name is mandatory.

A regexp argument is tested against the full rule-name.

If a subroutine reference is provided, the subroutine is called for each rule in the class, and the rule is disabled if the subroutine returns a true value.

    disables_superclass_rules qw(Parent::Parser::Class/parent_rule Another::Class/another_rule);
    disables_superclass_rules qr/Parent::Parser::Class\/comm.*/;
    disables_superclass_rules sub {
        my $rulename = shift;
        $rulename =~ /[@]/;
    };

=head2 unwraps_lines_using

This function may be used if one wants to specify a custom line-unwrapping routine. Takes a hash argument with mandatory keys as follows:

    unwraps_lines_using(
        is_wrapped     => sub { # Should return a boolean for each $line
            1;
        }, 
        unwrap_routine => sub { # Should return a string for each $last and $line
            my ($self, $last, $line) = @_;
            $last.$line;
        }, 
    );

For the pair of routines to not cause unexpected C<undef> results, they should return defined values always. To effectively unwrap lines, the C<is_wrapped> routine should return a boolean C<1> when it encounters the continuation character, and C<unwrap_routine> should return a string that appropriately joins the last and current line together.

=head1 SEE ALSO

=over 4

=item *

L<Text::Parser::Manual::ExtendedAWKSyntax> - Read this manual to learn how to do cool things with this class

=item *

L<Text::Parser::Error> - there is a change in how exceptions are thrown by this class. Read this page for more information.

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
