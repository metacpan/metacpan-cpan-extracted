package Test2::Tools::TypeTiny;

# ABSTRACT: Test2 tools for checking Type::Tiny types
use version;
our $VERSION = 'v0.93.1'; # VERSION

use v5.18;
use strict;
use warnings;

use parent 'Exporter';

use List::Util v1.29 qw< uniq shuffle pairmap pairs >;
use Scalar::Util     qw< blessed refaddr >;

use Test2::API              qw< context run_subtest >;
use Test2::Tools::Basic;
use Test2::Tools::Compare   qw< is like >;
use Test2::Tools::Exception qw< lives dies >;
use Test2::Compare          qw< compare strict_convert >;

use Data::Dumper;

use namespace::clean;

our $DEBUG_INDENT = 4;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Test2::V0;
#pod     use Test2::Tools::TypeTiny;
#pod
#pod     use MyTypes qw< FullyQualifiedDomainName >;
#pod
#pod     type_subtest FullyQualifiedDomainName, sub {
#pod         my $type = shift;
#pod
#pod         should_pass_initially(
#pod             $type,
#pod             qw<
#pod                 www.example.com
#pod                 example.com
#pod                 www123.prod.some.domain.example.com
#pod                 llanfairpwllgwyngllgogerychwyrndrobwllllantysiliogogogoch.co.uk
#pod             >,
#pod         );
#pod         should_fail(
#pod             $type,
#pod             qw< www ftp001 .com domains.t x.c prod|ask|me -prod3.example.com >,
#pod         );
#pod         should_coerce_into(
#pod             $type,
#pod             qw<
#pod                 ftp001-prod3                ftp001-prod3.ourdomain.com
#pod                 prod-ask-me                 prod-ask-me.ourdomain.com
#pod                 nonprod3-foobar-me          nonprod3-foobar-me.ourdomain.com
#pod             >,
#pod         );
#pod         should_sort_into(
#pod             $type,
#pod             [qw< ftp001-prod3 ftp001-prod3.ourdomain.com prod-ask-me.ourdomain.com >],
#pod         );
#pod
#pod         parameters_should_create_type(
#pod             $type,
#pod             [], [3], [0, 0], [1, 2],
#pod         );
#pod         parameters_should_die_as(
#pod             $type,
#pod             [],    qr<Parameter for .+ does not exist>,
#pod             [-3],  qr<Parameter for .+ is not a positive int>,
#pod             [0.2], qr<Parameter for .+ is not a positive int>,
#pod         );
#pod
#pod         message_should_report_as(
#pod             $type,
#pod             undef, qr<Must be a valid FQDN>
#pod         );
#pod         explanation_should_report_as(
#pod             $type,
#pod             undef, [
#pod                 qr<Undef did not pass type constraint>,
#pod             ],
#pod         );
#pod     };
#pod
#pod     done_testing;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides a set of tools for checking L<Type::Tiny> types.  This is similar to
#pod L<Test::TypeTiny>, but works against the L<Test2::Suite> and has more functionality for testing
#pod and troubleshooting coercions, error messages, and other aspects of the type.
#pod
#pod =head1 FUNCTIONS
#pod
#pod All functions are exported by default.  These functions create L<buffered subtests|Test2::Tools::Subtest/BUFFERED>
#pod to contain different classes of tests.
#pod
#pod Besides the wrapper itself, these functions are most useful wrapped inside of a L</type_subtest>
#pod coderef.
#pod
#pod =cut

our @EXPORT_OK = (qw<
    type_subtest
    should_pass_initially should_fail_initially should_pass should_fail should_coerce_into
    parameters_should_create_type parameters_should_die_as
    message_should_report_as explanation_should_report_as
    should_sort_into
>);
our @EXPORT = @EXPORT_OK;

#pod =head2 Wrappers
#pod
#pod =head3 type_subtest
#pod
#pod     type_subtest Type, sub {
#pod         my $type = shift;
#pod
#pod         ...
#pod     };
#pod
#pod Creates a subtest with the given type as the test name, and passed as the only parameter.  Using a
#pod generic C<$type> variable makes it much easier to copy and paste test code from other type tests
#pod without accidentally forgetting to change your custom type within the code.
#pod
#pod If the type can be inlined, this will also run two separate subtests (within the main type subtest)
#pod to check both the inlined constraint and the slower coderef constraint.  The second subtest will
#pod have a inline-less type, cloned from the original type.  This is done by stripping out the inlined
#pod constraint (or generator) in the clone.
#pod
#pod The tester sub will be used in both subtests.  If you need the inlined constraint for certain
#pod tests, you can use the C<< $type->can_be_inlined >> method to check which version of the test its
#pod running.  However, inlined checks should do the exact same thing as coderef checks, so keep these
#pod kind of exceptions to a minimum.
#pod
#pod Note that it doesn't do anything to the parent types.  If your type check is solely relying on
#pod parent checks, this will only run the one subtest.  If the parent checks are part of your package,
#pod you should check those separately.
#pod
#pod =cut

sub type_subtest ($&) {
    my ($type, $tester_coderef) = @_;

    my $ctx = context();
    my $pass;

    # XXX: Private method abuse
    if (!$type->_is_null_constraint && $type->has_inlined) {
        $pass = run_subtest(
            "Type Test: ".$type->display_name,
            \&_multi_type_split_subtest,
            { buffered => 1, inherit_trace => 1 },
            $type, $tester_coderef,
        );
    }
    else {
        $pass = run_subtest(
            "Type Test: ".$type->display_name,
            $tester_coderef,
            { buffered => 1 },
            $type,
        );
    }

    $ctx->release;

    return $pass;
}

sub _multi_type_split_subtest {
    my ($type, $tester_coderef) = @_;
    my $ctx = context();

    plan 2;

    my $orig_result = run_subtest(
        'original type',
        $tester_coderef,
        { buffered => 1 },
        $type,
    );

    ### XXX: There is some internal mechanics abuse to try to get this type, because Type::Tiny
    ### doesn't really have a $type->create_inlineless_type method, and methods like _clone and
    ### create_child_type don't cleanly do what we want.  (We don't want a child type that
    ### would be impacted by parental inlined constraints.)

    # Create the inline-less type
    my %inlineless_opts = %$type;
    delete $inlineless_opts{$_} for qw<
        compiled_type_constraint uniq tmp
        inlined inline_generator
        _overload_coderef _overload_coderef_no_rebuild
    >;
    $inlineless_opts{display_name} .= ' (inline-less)';

    my $inlineless_type = blessed($type)->new(%inlineless_opts);

    my $inlineless_result = run_subtest(
        'inline-less type',
        $tester_coderef,
        { buffered => 1 },
        $inlineless_type,
    );

    $ctx->release;
    return $orig_result && $inlineless_result;
}

#pod =head2 Value Testers
#pod
#pod Most of these checks will run through C<get_message> and C<validate_explain> calls to confirm the
#pod coderefs don't die.  If you need to validate the error messages themselves, consider using some of
#pod the L</Error Message Testers>.
#pod
#pod =head3 should_pass_initially
#pod
#pod     should_pass_initially($type, @values);
#pod
#pod Creates a subtest that confirms the type will pass with all of the given C<@values>, without any
#pod need for coercions.
#pod
#pod =cut

sub should_pass_initially {
    my $ctx  = context();
    my $pass = run_subtest(
        'should pass (without coercions)',
        \&_should_pass_initially_subtest,
        { buffered => 1, inherit_trace => 1 },
        @_,
    );
    $ctx->release;

    return $pass;
}

sub _should_pass_initially_subtest {
    my ($type, @values) = @_;

    plan scalar @values;

    foreach my $value (@values) {
        my $val_dd      = _dd($value);
        my @val_explain = _constraint_type_check_debug_map($type, $value);
        _check_error_message_methods($type, $value);

        ok $type->check($value), "$val_dd should pass", @val_explain;
    }
}

#pod =head3 should_fail_initially
#pod
#pod     should_fail_initially($type, @values);
#pod
#pod Creates a subtest that confirms the type will fail with all of the given C<@values>, without using
#pod any coercions.
#pod
#pod This function is included for completeness.  However, items in C<should_fail_initially> should
#pod realistically end up in either a L</should_fail> block (if it always fails, even with coercions) or
#pod a L</should_coerce_into> block (if it would pass after coercions).
#pod
#pod =cut

sub should_fail_initially {
    my $ctx  = context();
    my $pass = run_subtest(
        'should fail (without coercions)',
        \&_should_fail_initially_subtest,
        { buffered => 1, inherit_trace => 1 },
        @_,
    );
    $ctx->release;

    return $pass;
}

sub _should_fail_initially_subtest {
    my ($type, @values) = @_;

    plan scalar @values;

    foreach my $value (@values) {
        my $val_dd      = _dd($value);
        my @val_explain = _constraint_type_check_debug_map($type, $value);
        _check_error_message_methods($type, $value);

        ok !$type->check($value), "$val_dd should fail", @val_explain;
    }
}

#pod =head3 should_pass
#pod
#pod     should_pass($type, @values);
#pod
#pod Creates a subtest that confirms the type will pass with all of the given C<@values>, including
#pod values that might need coercions.  If it initially passes, that's okay, too.  If the type does not
#pod have a coercion and it fails the initial check, it will stop there and fail the test.
#pod
#pod This function is included for completeness.  However, L</should_coerce_into> is the better function
#pod for types with known coercions, as it checks the resulting coerced values as well.
#pod
#pod =cut

sub should_pass {
    my $ctx  = context();
    my $pass = run_subtest(
        'should pass',
        \&_should_pass_subtest,
        { buffered => 1, inherit_trace => 1 },
        @_,
    );
    $ctx->release;

    return $pass;
}

sub _should_pass_subtest {
    my ($type, @values) = @_;

    plan scalar @values;

    foreach my $value (@values) {
        my $val_dd      = _dd($value);
        my @val_explain = _constraint_type_check_debug_map($type, $value);
        _check_error_message_methods($type, $value);

        if ($type->check($value)) {
            pass "$val_dd should pass (initial check)", @val_explain;
            next;
        }
        elsif (!$type->has_coercion) {
            fail "$val_dd should pass (no coercion)", @val_explain;
            next;
        }

        # try to coerce then
        my @coercion_debug = _coercion_type_check_debug_map($type, $value);
        my $new_value      = $type->coerce($value);
        my $new_dd         = _dd($new_value);
        unless (_check_coercion($value, $new_value)) {
            fail "$val_dd should pass (failed coercion)", @val_explain, @coercion_debug;
            next;
        }
        _check_error_message_methods($type, $new_value);

        # final check
        @val_explain = _constraint_type_check_debug_map($type, $new_value);
        ok $type->check($new_value), "$val_dd should pass (coerced into $new_dd)", @val_explain, @coercion_debug;
    }
}

#pod =head3 should_fail
#pod
#pod     should_fail($type, @values);
#pod
#pod Creates a subtest that confirms the type will fail with all of the given C<@values>, even when
#pod those values are ran through its coercions.
#pod
#pod =cut

sub should_fail {
    my $ctx  = context();
    my $pass = run_subtest(
        'should fail',
        \&_should_fail_subtest,
        { buffered => 1, inherit_trace => 1 },
        @_,
    );
    $ctx->release;

    return $pass;
}

sub _should_fail_subtest {
    my ($type, @values) = @_;

    plan scalar @values;

    foreach my $value (@values) {
        my $val_dd      = _dd($value);
        my @val_explain = _constraint_type_check_debug_map($type, $value);
        _check_error_message_methods($type, $value);

        if ($type->check($value)) {
            fail "$val_dd should fail (initial check)", @val_explain;
            next;
        }
        elsif (!$type->has_coercion) {
            pass "$val_dd should fail (no coercion)", @val_explain;
            next;
        }

        # try to coerce then
        my @coercion_debug = _coercion_type_check_debug_map($type, $value);
        my $new_value      = $type->coerce($value);
        my $new_dd         = _dd($new_value);
        unless (_check_coercion($value, $new_value)) {
            pass "$val_dd should fail (failed coercion)", @val_explain, @coercion_debug;
            next;
        }
        _check_error_message_methods($type, $new_value);

        # final check
        @val_explain = _constraint_type_check_debug_map($type, $new_value);
        ok !$type->check($new_value), "$val_dd should fail (coerced into $new_dd)", @val_explain, @coercion_debug;
    }
}

#pod =head3 should_coerce_into
#pod
#pod     should_coerce_into($type, @orig_coerced_kv_pairs);
#pod     should_coerce_into($type,
#pod         # orig  # coerced
#pod         undef,  0,
#pod         [],     0,
#pod     );
#pod
#pod Creates a subtest that confirms the type will take the "key" in C<@orig_coerced_kv_pairs> and
#pod coerce it into the "value" in C<@orig_coerced_kv_pairs>. (The C<@orig_coerced_kv_pairs> parameter
#pod is essentially an ordered hash here, with support for ref values as the "key".)
#pod
#pod The original value should not pass initial checks, as it would not be coerced in most use cases.
#pod These would be considered test failures.
#pod
#pod =cut

sub should_coerce_into {
    my $ctx  = context();
    my $pass = run_subtest(
        'should coerce into',
        \&_should_coerce_into_subtest,
        { buffered => 1, inherit_trace => 1 },
        @_,
    );
    $ctx->release;

    return $pass;
}

sub _should_coerce_into_subtest {
    my ($type, @kv_pairs) = @_;

    plan int( scalar(@kv_pairs) / 2 );

    foreach my $kv (pairs @kv_pairs) {
        my ($value, $expected) = @$kv;

        my $val_dd      = _dd($value);
        my @val_explain = _constraint_type_check_debug_map($type, $value);
        _check_error_message_methods($type, $value);

        if ($type->check($value)) {
            fail "$val_dd should fail (initial check)";
            next;
        }
        elsif (!$type->has_coercion) {
            fail "$val_dd should coerce (no coercion)";
            next;
        }

        # try to coerce then
        my @coercion_debug = _coercion_type_check_debug_map($type, $value);
        my $new_value      = $type->coerce($value);
        my $new_dd         = _dd($new_value);
        unless (_check_coercion($value, $new_value)) {
            fail "$val_dd should coerce", @val_explain, @coercion_debug;
            next;
        }
        _check_error_message_methods($type, $new_value);

        # make sure it matches the expected value
        @val_explain = _constraint_type_check_debug_map($type, $new_value);
        is $new_value, $expected, "$val_dd (coerced)", @val_explain, @coercion_debug;
    }
}

#pod =head2 Parameter Testers
#pod
#pod These tests should only be used for parameter validation.  None of the resulting types are checked
#pod in other ways, so you should include other L<type subtests|/type_subtest> with different kinds of
#pod parameterized types.
#pod
#pod Note that L<inline generators|Type::Tiny/inline_generator> don't require any sort of validation
#pod because the L<constraint generator|Type::Tiny/constraint_generator> is always called first, and
#pod should die on parameter validation failure, prior to the C<inline_generator> call.  The same applies
#pod for coercion generators as well.
#pod
#pod =head3 parameters_should_create_type
#pod
#pod     parameters_should_create_type($type, @parameter_sets);
#pod     parameters_should_create_type($type,
#pod         [],
#pod         [3],
#pod         [0, 0],
#pod         [1, 2],
#pod     );
#pod
#pod Creates a subtest that confirms the type will successfully create a parameterized type with each of
#pod the set of parameters in C<@parameter_sets> (a list of arrayrefs).
#pod
#pod =cut

sub parameters_should_create_type {
    my $type = shift;
    die $type->display_name." is not a parameterized type" unless $type->is_parameterizable;

    my $ctx  = context();
    my $pass = run_subtest(
        'parameters should create type',
        \&_parameters_should_create_type_subtest,
        { buffered => 1, inherit_trace => 1 },
        $type, @_,
    );
    $ctx->release;

    return $pass;
}

sub _parameters_should_create_type_subtest {
    my ($type, @parameter_sets) = @_;

    plan scalar(@parameter_sets);

    foreach my $parameter_set (@parameter_sets) {
        my $val_dd = _dd($parameter_set);

        # NOTE: lives is a separate statement, so that $@ is populated after failure
        my $new_type;
        my $ok = lives { $new_type = $type->of(@$parameter_set) };
        ok($ok, $val_dd, "Reported exception: $@");

        # XXX: no idea what it takes in, so just pass in a few values
        next unless $new_type;
        _check_error_message_methods($new_type, $_) for (1, 0, -1, undef, \"", {}, []);
    }
}

#pod =head3 parameters_should_die_as
#pod
#pod     parameters_should_die_as($type, @parameter_sets_exception_regex_pairs);
#pod     parameters_should_die_as($type,
#pod         # params  # exceptions
#pod         [],       qr<Parameter for .+ does not exist>,
#pod         [-3],     qr<Parameter for .+ is not a positive int>,
#pod         [0.2],    qr<Parameter for .+ is not a positive int>,
#pod     );
#pod
#pod Creates a subtest that confirms the type will fail validation (fatally) with the given parameters
#pod and exceptions.  The RHS should be an regular expression, but can be anything that
#pod L<like|Test2::Tools::Compare> accepts.
#pod
#pod =cut

sub parameters_should_die_as {
    my $type = shift;
    die $type->display_name." is not a parameterized type" unless $type->is_parameterizable;

    my $ctx  = context();
    my $pass = run_subtest(
        'parameters should die as',
        \&_parameters_should_die_as_subtest,
        { buffered => 1, inherit_trace => 1 },
        $type, @_,
    );
    $ctx->release;

    return $pass;
}

sub _parameters_should_die_as_subtest {
    my ($type, @pairs) = @_;

    plan int( scalar(@pairs) / 2 );

    foreach my $pair (pairs @pairs) {
        my ($parameter_set, $expected) = @$pair;
        my $val_dd = _dd($parameter_set);

        like(
            dies { $type->of(@$parameter_set) },
            $expected,
            $val_dd,
        );
    }
}

#pod =head2 Error Message Testers
#pod
#pod =head3 message_should_report_as
#pod
#pod     message_should_report_as($type, @value_message_regex_pairs);
#pod     message_should_report_as($type,
#pod         # values       # messages
#pod         1,             qr<Must be a fully-qualified domain name, not 1>,
#pod         undef,         qr!Must be a fully-qualified domain name, not <undef>!,
#pod         # valid value; checking message, anyway
#pod         'example.com', qr<Must be a fully-qualified domain name, not example.com>,
#pod     );
#pod
#pod Creates a subtest that confirms error message output against the value.  Technically,
#pod L<Type::Tiny/get_message> works for valid values, too, so this isn't actually trapping assertion
#pod failures, just checking the output of that method.
#pod
#pod The RHS should be an regular expression, but it can be anything that L<like|Test2::Tools::Compare>
#pod accepts.
#pod
#pod =cut

sub message_should_report_as {
    my $ctx  = context();
    my $pass = run_subtest(
        'message should report as',
        \&_message_should_report_as_subtest,
        { buffered => 1, inherit_trace => 1 },
        @_,
    );
    $ctx->release;

    return $pass;
}

sub _message_should_report_as_subtest {
    my ($type, @pairs) = @_;

    plan int( scalar(@pairs) / 2 );

    foreach my $pair (pairs @pairs) {
        my ($value, $message_check) = @$pair;
        my $val_dd = _dd($value);

        my $message_got = $type->get_message($value);

        like $message_got, $message_check, $val_dd;
    }
}

#pod =head3 explanation_should_report_as
#pod
#pod     explanation_should_report_as($type, @value_explanation_check_pairs);
#pod     explanation_should_report_as($type,
#pod         # values       # explanation check
#pod         'example.com', [
#pod             qr< did not pass type constraint >,
#pod             qr< expects domain label count \(\?LD\) to be between 3 and 5>,
#pod             qr<\$_ appears to be a 2LD>,
#pod         ],
#pod         undef,         [
#pod             qr< did not pass type constraint >,
#pod             qr<\$_ is not a legal FQDN>,
#pod         ],
#pod     );
#pod
#pod Creates a subtest that confirms deeper explanation message output from L<Type::Tiny/validate_explain>
#pod against the value.  Unlike C<get_message>, C<validate_explain> actually needs failed values to
#pod report back a string message.  The second parameter to C<validate_explain> is not passed, so expect
#pod error messages that inspect C<$_>.
#pod
#pod The RHS should be an arrayref of regular expressions, since C<validate_explain> reports back an
#pod arrayref of strings.  Although, it can be anything that L<like|Test2::Tools::Compare> accepts, and
#pod since it's a looser check, gaps in the arrayref are allowed.
#pod
#pod =cut

sub explanation_should_report_as {
    my $ctx  = context();
    my $pass = run_subtest(
        'explanation should report as',
        \&_explanation_should_report_as_subtest,
        { buffered => 1, inherit_trace => 1 },
        @_,
    );
    $ctx->release;

    return $pass;
}

sub _explanation_should_report_as_subtest {
    my ($type, @pairs) = @_;

    plan int( scalar(@pairs) / 2 );

    foreach my $pair (pairs @pairs) {
        my ($value, $explanation_check) = @$pair;
        my $val_dd = _dd($value);

        my $explanation_got = $type->validate_explain($value);

        my @explanation_explain =
            defined $explanation_got ? ( "Resulting Explanation:", map { "    $_" } @$explanation_got ) :
            ()
        ;
        like $explanation_got, $explanation_check, $val_dd, @explanation_explain;
    }
}

#pod =head2 Other Testers
#pod
#pod =head3 should_sort_into
#pod
#pod     should_sort_into($type, @sorted_arrayrefs);
#pod
#pod Creates a subtest that confirms the type will sort into the expected lists given.  The input list
#pod is a shuffled version of the sorted list.
#pod
#pod Because this introduces some non-deterministic behavior to the test, it will run through 100 cycles
#pod of shuffling and sorting to confirm the results.  A good sorter should always return a
#pod deterministic result for a given list, with enough fallbacks to account for every unique case.
#pod Any failure will immediate stop the loop and return both the shuffled input and output list in the
#pod failure output, so that you can temporarily test in a more deterministic manner, as you debug the
#pod fault.
#pod
#pod =cut

sub should_sort_into {
    my $ctx  = context();
    my $pass = run_subtest(
        'should sort into',
        \&_should_sort_into_subtest,
        { buffered => 1, inherit_trace => 1 },
        @_,
    );
    $ctx->release;

    return $pass;
}

sub _should_sort_into_subtest {
    my ($type, @sorted_lists) = @_;

    plan scalar(@sorted_lists);

    foreach my $sorted_list (@sorted_lists) {
        my @expected_sort = @$sorted_list;

        my $val_dd = _dd(\@expected_sort);

        my (@shuffled, @sorted);
        foreach my $i (1..100) {
            @shuffled = shuffle @expected_sort;
            @sorted   = $type->sort(@shuffled);

            # To hide all of these iterations, we'll compare with 'compare' first, and if it's a failure,
            # we'll use 'is' to advertise the failure.
            my $delta = compare(\@sorted, \@expected_sort, \&strict_convert);
            last if $delta;  # let 'is' fail
        }

        # pass or fail
        my @io_explain = (
            "Shuffled Input:   "._dd(\@shuffled),
            "Resulting Output: "._dd(\@sorted),
        );
        is \@sorted, \@expected_sort, $val_dd, @io_explain;
    }
}

# Helpers
sub _dd {
    my $dd  = Data::Dumper->new([ shift ])->Terse(1)->Indent(0)->Useqq(1)->Deparse(1)->Quotekeys(0)->Sortkeys(1)->Maxdepth(2);
    my $val = $dd->Dump;
    $val =~ s/\s+/ /gs;
    return $val;
};

sub _constraint_type_check_debug_map {
    my ($type, $value) = @_;

    my $dd = _dd($value);

    my @diag_map = ($type->display_name." constraint map:");
    if (length $dd > 30) {
        push @diag_map, "    Full value: $dd";
        $dd = '...';
    }

    my $current_check = $type;
    while ($current_check) {
        my $type_name = $current_check->display_name;
        my $check     = $current_check->check($value);

        my $check_label = $check ? 'PASSED' : 'FAILED';
        push @diag_map, sprintf('%*s%s->check(%s) ==> %s', $DEBUG_INDENT, '', $type_name, $dd, $check_label);

        # Advertize failure message and deeper explanations
        unless ($check) {
            push @diag_map, sprintf('%*s%s: %s', $DEBUG_INDENT * 2, '', 'message', $current_check->get_message($value));

            if ($current_check->is_parameterized && $current_check->parent->has_deep_explanation) {
                push @diag_map, sprintf('%*s%s:', $DEBUG_INDENT * 2, '', 'parameterized deep explanation (from parent)');
                my $deep = eval { $current_check->parent->deep_explanation->( $current_check, $value, '$_' ) };

                # Account for bugs in parent->deep_explanation
                push @diag_map, (
                    $@                   ? sprintf('%*s%s: %s', $DEBUG_INDENT * 3, '', 'EVAL ERROR', $@) :
                    !defined $deep       ? sprintf('%*s%s',     $DEBUG_INDENT * 3, '', 'NO RESULTS') :
                    ref $deep ne 'ARRAY' ? sprintf('%*s%s: %s', $DEBUG_INDENT * 3, '', 'ILLEGAL RETURN TYPE', ref $deep) :
                    (map { sprintf('%*s%s', $DEBUG_INDENT * 3, '', $_) } @$deep)
                );
            }
        }

        local $SIG{__WARN__} = sub {};
        push @diag_map, sprintf('%*s%s: %s', $DEBUG_INDENT * 2, '', 'is defined as', $current_check->_perlcode);

        $current_check = $current_check->parent;
    };

    return @diag_map;
}

sub _coercion_type_check_debug_map {
    my ($type, $value) = @_;

    my $dd = _dd($value);

    my @diag_map = ($type->display_name." coercion map:");
    if (length $dd > 30) {
        push @diag_map, sprintf('%*s%s: %s', $DEBUG_INDENT, '', 'Full value', $dd);
        $dd = '...';
    }

    foreach my $coercion_type ($type, (pairmap { $a } @{$type->coercion->type_coercion_map}) ) {
        my $type_name = $coercion_type->display_name;
        my $check     = $coercion_type->check($value);

        my $check_label = $check ? 'PASSED' : 'FAILED';
        $check_label .= sprintf ' (coerced into %s)', _dd($type->coerce($value)) if $check && $coercion_type != $type;

        push @diag_map, sprintf('%*s%s->check(%s) ==> %s', $DEBUG_INDENT, '', $type_name, $dd, $check_label);
        last if $check;
    }

    return @diag_map;
}

sub _check_coercion {
    my ($old_value, $new_value) = @_;
    $old_value //= '';
    $new_value //= '';

    # compare memory addresses for refs instead
    ($old_value, $new_value) = map { refaddr($_) // '' } ($old_value, $new_value)
        if ref $old_value || ref $new_value
    ;

    # returns true if it was coerced
    return $old_value ne $new_value;
}

sub _check_error_message_methods {
    my ($type, $value) = @_;

    # If it dies, we just let it naturally die
    $type->get_message($value);
    $type->validate_explain($value);  # will return undef on good values
}

#pod =head1 TROUBLESHOOTING
#pod
#pod =head2 Test name output
#pod
#pod The test names within each C<should_*> function are somewhat dynamic, depending on which stage of
#pod the test it failed at.  Most of the time, this is self-explanatory, but double negatives may make
#pod the output a tad logic-twisting:
#pod
#pod     not ok 1 - ...
#pod
#pod     # should_*_initially
#pod     "val" should pass                        # simple should_pass_initially failure
#pod     "val" should fail                        # simple should_fail_initially failure
#pod
#pod     # should_*
#pod     "val" should fail (initial check)        # should_fail didn't initially fail
#pod     "val" should pass (no coercion)          # should_pass initally failed, and didn't have a coercion to use
#pod     "val" should pass (failed coercion)      # should_pass failed both the check and coercion
#pod     "val" should fail (coerced into "val2")  # should_fail still successfully coerced into a good value
#pod     "val" should pass (coerced into "val2")  # should_pass coerced into a bad value
#pod
#pod     # should_coerce_into has similar errors as above
#pod
#pod =head3 Type Map Diagnostics
#pod
#pod Because types can be twisty mazes of inherited parents or multiple coercion maps, any failures will
#pod produce a verbose set of diagnostics.  These come in two flavors: constraint maps and coercion maps,
#pod depending on where in the process the test failed.
#pod
#pod For example, a constraint map could look like:
#pod
#pod     # (some definition output truncated)
#pod
#pod     MyStringType constraint map:
#pod         MyStringType->check("value") ==> FAILED
#pod             message: Must be a good value
#pod             is defined as: do { package Type::Tiny; ... ) }
#pod         StrMatch["(?^ux:...)"]->check("value") ==> FAILED
#pod             message: StrMatch did not pass type constraint: ...
#pod             is defined as: do { package Type::Tiny; !ref($_) and !!( $_ =~ $Types::Standard::StrMatch::expressions{"..."} ) }
#pod         StrMatch->check("value") ==> PASSED
#pod             is defined as: do { package Type::Tiny; defined($_) and do { ref(\$_) eq 'SCALAR' or ref(\(my $val = $_)) eq 'SCALAR' } }
#pod         Str->check("value") ==> PASSED
#pod             is defined as: do { package Type::Tiny; defined($_) and do { ref(\$_) eq 'SCALAR' or ref(\(my $val = $_)) eq 'SCALAR' } }
#pod         Value->check("value") ==> PASSED
#pod             is defined as: (defined($_) and not ref($_))
#pod         Defined->check("value") ==> PASSED
#pod             is defined as: (defined($_))
#pod         Item->check("value") ==> PASSED
#pod             is defined as: (!!1)
#pod         Any->check("value") ==> PASSED
#pod             is defined as: (!!1)
#pod
#pod The diagnostics checked the final value with each individual parent check (including itself).
#pod Based on this output, the value passed all of the lower-level C<Str> checks, because it is a string.
#pod But, it failed the more-specific C<StrMatch> regular expression.  This will give you an idea of
#pod which type to adjust, if necessary.
#pod
#pod A coercion map would look like this:
#pod
#pod     MyStringType coercion map:
#pod         MyStringType->check("value") ==> FAILED
#pod         FQDN->check("value") ==> FAILED
#pod         Username->check("value") ==> FAILED
#pod         Hostname->check("value") ==> PASSED (coerced into "value2")
#pod
#pod The diagnostics looked at L<Type::Coercion>'s C<type_coercion_map> (and the type itself), figured
#pod out which types were acceptable for coercion, and returned the coercion result that passed.  In
#pod this case, none of the types passed except C<Hostname>, which was coerced into C<value2>.
#pod
#pod Based on this, either C<Hostname> converted it to the wrong value (one that did not pass
#pod C<MyStringType>), or one of the higher-level checks should have passed and didn't.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::TypeTiny - Test2 tools for checking Type::Tiny types

=head1 VERSION

version v0.93.1

=head1 SYNOPSIS

    use Test2::V0;
    use Test2::Tools::TypeTiny;

    use MyTypes qw< FullyQualifiedDomainName >;

    type_subtest FullyQualifiedDomainName, sub {
        my $type = shift;

        should_pass_initially(
            $type,
            qw<
                www.example.com
                example.com
                www123.prod.some.domain.example.com
                llanfairpwllgwyngllgogerychwyrndrobwllllantysiliogogogoch.co.uk
            >,
        );
        should_fail(
            $type,
            qw< www ftp001 .com domains.t x.c prod|ask|me -prod3.example.com >,
        );
        should_coerce_into(
            $type,
            qw<
                ftp001-prod3                ftp001-prod3.ourdomain.com
                prod-ask-me                 prod-ask-me.ourdomain.com
                nonprod3-foobar-me          nonprod3-foobar-me.ourdomain.com
            >,
        );
        should_sort_into(
            $type,
            [qw< ftp001-prod3 ftp001-prod3.ourdomain.com prod-ask-me.ourdomain.com >],
        );

        parameters_should_create_type(
            $type,
            [], [3], [0, 0], [1, 2],
        );
        parameters_should_die_as(
            $type,
            [],    qr<Parameter for .+ does not exist>,
            [-3],  qr<Parameter for .+ is not a positive int>,
            [0.2], qr<Parameter for .+ is not a positive int>,
        );

        message_should_report_as(
            $type,
            undef, qr<Must be a valid FQDN>
        );
        explanation_should_report_as(
            $type,
            undef, [
                qr<Undef did not pass type constraint>,
            ],
        );
    };

    done_testing;

=head1 DESCRIPTION

This module provides a set of tools for checking L<Type::Tiny> types.  This is similar to
L<Test::TypeTiny>, but works against the L<Test2::Suite> and has more functionality for testing
and troubleshooting coercions, error messages, and other aspects of the type.

=head1 FUNCTIONS

All functions are exported by default.  These functions create L<buffered subtests|Test2::Tools::Subtest/BUFFERED>
to contain different classes of tests.

Besides the wrapper itself, these functions are most useful wrapped inside of a L</type_subtest>
coderef.

=head2 Wrappers

=head3 type_subtest

    type_subtest Type, sub {
        my $type = shift;

        ...
    };

Creates a subtest with the given type as the test name, and passed as the only parameter.  Using a
generic C<$type> variable makes it much easier to copy and paste test code from other type tests
without accidentally forgetting to change your custom type within the code.

If the type can be inlined, this will also run two separate subtests (within the main type subtest)
to check both the inlined constraint and the slower coderef constraint.  The second subtest will
have a inline-less type, cloned from the original type.  This is done by stripping out the inlined
constraint (or generator) in the clone.

The tester sub will be used in both subtests.  If you need the inlined constraint for certain
tests, you can use the C<< $type->can_be_inlined >> method to check which version of the test its
running.  However, inlined checks should do the exact same thing as coderef checks, so keep these
kind of exceptions to a minimum.

Note that it doesn't do anything to the parent types.  If your type check is solely relying on
parent checks, this will only run the one subtest.  If the parent checks are part of your package,
you should check those separately.

=head2 Value Testers

Most of these checks will run through C<get_message> and C<validate_explain> calls to confirm the
coderefs don't die.  If you need to validate the error messages themselves, consider using some of
the L</Error Message Testers>.

=head3 should_pass_initially

    should_pass_initially($type, @values);

Creates a subtest that confirms the type will pass with all of the given C<@values>, without any
need for coercions.

=head3 should_fail_initially

    should_fail_initially($type, @values);

Creates a subtest that confirms the type will fail with all of the given C<@values>, without using
any coercions.

This function is included for completeness.  However, items in C<should_fail_initially> should
realistically end up in either a L</should_fail> block (if it always fails, even with coercions) or
a L</should_coerce_into> block (if it would pass after coercions).

=head3 should_pass

    should_pass($type, @values);

Creates a subtest that confirms the type will pass with all of the given C<@values>, including
values that might need coercions.  If it initially passes, that's okay, too.  If the type does not
have a coercion and it fails the initial check, it will stop there and fail the test.

This function is included for completeness.  However, L</should_coerce_into> is the better function
for types with known coercions, as it checks the resulting coerced values as well.

=head3 should_fail

    should_fail($type, @values);

Creates a subtest that confirms the type will fail with all of the given C<@values>, even when
those values are ran through its coercions.

=head3 should_coerce_into

    should_coerce_into($type, @orig_coerced_kv_pairs);
    should_coerce_into($type,
        # orig  # coerced
        undef,  0,
        [],     0,
    );

Creates a subtest that confirms the type will take the "key" in C<@orig_coerced_kv_pairs> and
coerce it into the "value" in C<@orig_coerced_kv_pairs>. (The C<@orig_coerced_kv_pairs> parameter
is essentially an ordered hash here, with support for ref values as the "key".)

The original value should not pass initial checks, as it would not be coerced in most use cases.
These would be considered test failures.

=head2 Parameter Testers

These tests should only be used for parameter validation.  None of the resulting types are checked
in other ways, so you should include other L<type subtests|/type_subtest> with different kinds of
parameterized types.

Note that L<inline generators|Type::Tiny/inline_generator> don't require any sort of validation
because the L<constraint generator|Type::Tiny/constraint_generator> is always called first, and
should die on parameter validation failure, prior to the C<inline_generator> call.  The same applies
for coercion generators as well.

=head3 parameters_should_create_type

    parameters_should_create_type($type, @parameter_sets);
    parameters_should_create_type($type,
        [],
        [3],
        [0, 0],
        [1, 2],
    );

Creates a subtest that confirms the type will successfully create a parameterized type with each of
the set of parameters in C<@parameter_sets> (a list of arrayrefs).

=head3 parameters_should_die_as

    parameters_should_die_as($type, @parameter_sets_exception_regex_pairs);
    parameters_should_die_as($type,
        # params  # exceptions
        [],       qr<Parameter for .+ does not exist>,
        [-3],     qr<Parameter for .+ is not a positive int>,
        [0.2],    qr<Parameter for .+ is not a positive int>,
    );

Creates a subtest that confirms the type will fail validation (fatally) with the given parameters
and exceptions.  The RHS should be an regular expression, but can be anything that
L<like|Test2::Tools::Compare> accepts.

=head2 Error Message Testers

=head3 message_should_report_as

    message_should_report_as($type, @value_message_regex_pairs);
    message_should_report_as($type,
        # values       # messages
        1,             qr<Must be a fully-qualified domain name, not 1>,
        undef,         qr!Must be a fully-qualified domain name, not <undef>!,
        # valid value; checking message, anyway
        'example.com', qr<Must be a fully-qualified domain name, not example.com>,
    );

Creates a subtest that confirms error message output against the value.  Technically,
L<Type::Tiny/get_message> works for valid values, too, so this isn't actually trapping assertion
failures, just checking the output of that method.

The RHS should be an regular expression, but it can be anything that L<like|Test2::Tools::Compare>
accepts.

=head3 explanation_should_report_as

    explanation_should_report_as($type, @value_explanation_check_pairs);
    explanation_should_report_as($type,
        # values       # explanation check
        'example.com', [
            qr< did not pass type constraint >,
            qr< expects domain label count \(\?LD\) to be between 3 and 5>,
            qr<\$_ appears to be a 2LD>,
        ],
        undef,         [
            qr< did not pass type constraint >,
            qr<\$_ is not a legal FQDN>,
        ],
    );

Creates a subtest that confirms deeper explanation message output from L<Type::Tiny/validate_explain>
against the value.  Unlike C<get_message>, C<validate_explain> actually needs failed values to
report back a string message.  The second parameter to C<validate_explain> is not passed, so expect
error messages that inspect C<$_>.

The RHS should be an arrayref of regular expressions, since C<validate_explain> reports back an
arrayref of strings.  Although, it can be anything that L<like|Test2::Tools::Compare> accepts, and
since it's a looser check, gaps in the arrayref are allowed.

=head2 Other Testers

=head3 should_sort_into

    should_sort_into($type, @sorted_arrayrefs);

Creates a subtest that confirms the type will sort into the expected lists given.  The input list
is a shuffled version of the sorted list.

Because this introduces some non-deterministic behavior to the test, it will run through 100 cycles
of shuffling and sorting to confirm the results.  A good sorter should always return a
deterministic result for a given list, with enough fallbacks to account for every unique case.
Any failure will immediate stop the loop and return both the shuffled input and output list in the
failure output, so that you can temporarily test in a more deterministic manner, as you debug the
fault.

=head1 TROUBLESHOOTING

=head2 Test name output

The test names within each C<should_*> function are somewhat dynamic, depending on which stage of
the test it failed at.  Most of the time, this is self-explanatory, but double negatives may make
the output a tad logic-twisting:

    not ok 1 - ...

    # should_*_initially
    "val" should pass                        # simple should_pass_initially failure
    "val" should fail                        # simple should_fail_initially failure

    # should_*
    "val" should fail (initial check)        # should_fail didn't initially fail
    "val" should pass (no coercion)          # should_pass initally failed, and didn't have a coercion to use
    "val" should pass (failed coercion)      # should_pass failed both the check and coercion
    "val" should fail (coerced into "val2")  # should_fail still successfully coerced into a good value
    "val" should pass (coerced into "val2")  # should_pass coerced into a bad value

    # should_coerce_into has similar errors as above

=head3 Type Map Diagnostics

Because types can be twisty mazes of inherited parents or multiple coercion maps, any failures will
produce a verbose set of diagnostics.  These come in two flavors: constraint maps and coercion maps,
depending on where in the process the test failed.

For example, a constraint map could look like:

    # (some definition output truncated)

    MyStringType constraint map:
        MyStringType->check("value") ==> FAILED
            message: Must be a good value
            is defined as: do { package Type::Tiny; ... ) }
        StrMatch["(?^ux:...)"]->check("value") ==> FAILED
            message: StrMatch did not pass type constraint: ...
            is defined as: do { package Type::Tiny; !ref($_) and !!( $_ =~ $Types::Standard::StrMatch::expressions{"..."} ) }
        StrMatch->check("value") ==> PASSED
            is defined as: do { package Type::Tiny; defined($_) and do { ref(\$_) eq 'SCALAR' or ref(\(my $val = $_)) eq 'SCALAR' } }
        Str->check("value") ==> PASSED
            is defined as: do { package Type::Tiny; defined($_) and do { ref(\$_) eq 'SCALAR' or ref(\(my $val = $_)) eq 'SCALAR' } }
        Value->check("value") ==> PASSED
            is defined as: (defined($_) and not ref($_))
        Defined->check("value") ==> PASSED
            is defined as: (defined($_))
        Item->check("value") ==> PASSED
            is defined as: (!!1)
        Any->check("value") ==> PASSED
            is defined as: (!!1)

The diagnostics checked the final value with each individual parent check (including itself).
Based on this output, the value passed all of the lower-level C<Str> checks, because it is a string.
But, it failed the more-specific C<StrMatch> regular expression.  This will give you an idea of
which type to adjust, if necessary.

A coercion map would look like this:

    MyStringType coercion map:
        MyStringType->check("value") ==> FAILED
        FQDN->check("value") ==> FAILED
        Username->check("value") ==> FAILED
        Hostname->check("value") ==> PASSED (coerced into "value2")

The diagnostics looked at L<Type::Coercion>'s C<type_coercion_map> (and the type itself), figured
out which types were acceptable for coercion, and returned the coercion result that passed.  In
this case, none of the types passed except C<Hostname>, which was coerced into C<value2>.

Based on this, either C<Hostname> converted it to the wrong value (one that did not pass
C<MyStringType>), or one of the higher-level checks should have passed and didn't.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 - 2025 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
