
use v5.14;
use warnings;

use Syntax::Construct 'package-version', 'package-block';

package Test::YAFT {
	use parent 'Exporter::Tiny';

	use Context::Singleton;
	use Ref::Util qw[];
	use Safe::Isa qw[];
	use Scalar::Util qw[];
	use Sub::Install qw[];

	use Test::Deep qw[];
	use Test::Differences qw[];
	use Test::More     v0.970 qw[];

	require Test::Warnings;

	use Test::YAFT::Arrange;
	use Test::YAFT::Attributes;
	use Test::YAFT::Cmp;
	use Test::YAFT::Cmp::Compare;
	use Test::YAFT::Cmp::Complement;
	use Test::YAFT::Got;

	# v5.14 forward prototype declaration to prevent warnings from attributes
	sub act (&;@);
	sub arrange (&);
	sub got (&);
	sub pass (;$);

	sub act (&;@)                   :Exported(all,helpers);
	sub arrange (&)                 :Exported(all,helpers);
	sub BAIL_OUT                    :Exported(all,helpers)      :From(\&Test::More::BAIL_OUT);
	sub cmp_details                 :Exportable(all,plumbings)  :From(\&Test::Deep::cmp_details);
	sub deep_diag                   :Exportable(all,plumbings)  :From(\&Test::Deep::deep_diag);
	sub diag                        :Exported(all,helpers)      :From(\&Test::More::diag);
	sub done_testing                :Exported(all,helpers)      :From(\&Test::More::done_testing);
	sub eq_deeply                   :Exportable(all,plumbings)  :From(\&Test::Deep::eq_deeply);
	sub expect_all                  :Exported(all,expectations) :From(\&Test::Deep::all);
	sub expect_any                  :Exported(all,expectations) :From(\&Test::Deep::any);
	sub expect_array                :Exported(all,expectations) :From(\&Test::Deep::array);
	sub expect_array_each           :Exported(all,expectations) :From(\&Test::Deep::array_each);
	sub expect_array_elements_only  :Exported(all,expectations) :From(\&Test::Deep::arrayelementsonly);
	sub expect_array_length         :Exported(all,expectations) :From(\&Test::Deep::arraylength);
	sub expect_array_length_only    :Exported(all,expectations) :From(\&Test::Deep::arraylengthonly);
	sub expect_bag                  :Exported(all,expectations) :From(\&Test::Deep::bag);
	sub expect_blessed              :Exported(all,expectations) :From(\&Test::Deep::blessed);
	sub expect_bool                 :Exported(all,expectations) :From(\&Test::Deep::bool);
	sub expect_code                 :Exported(all,expectations) :From(\&Test::Deep::code);
	sub expect_compare              :Exported(all,expectations) :Cmp_Builder(Test::YAFT::Cmp::Compare);
	sub expect_complement           :Exported(all,expectations) :Cmp_Builder(Test::YAFT::Cmp::Complement);
	sub expect_false                :Exported(all,expectations);
	sub expect_hash                 :Exported(all,expectations) :From(\&Test::Deep::hash);
	sub expect_hash_each            :Exported(all,expectations) :From(\&Test::Deep::hash_each);
	sub expect_hash_keys            :Exported(all,expectations) :From(\&Test::Deep::hashkeys);
	sub expect_hash_keys_only       :Exported(all,expectations) :From(\&Test::Deep::hashkeysonly);
	sub expect_isa                  :Exported(all,expectations) :From(\&Test::Deep::Isa);
	sub expect_listmethods          :Exported(all,expectations) :From(\&Test::Deep::listmethods);
	sub expect_methods              :Exported(all,expectations) :From(\&Test::Deep::methods);
	sub expect_no_class             :Exported(all,expectations) :From(\&Test::Deep::noclass);
	sub expect_none                 :Exported(all,expectations) :From(\&Test::Deep::none);
	sub expect_none_of              :Exported(all,expectations) :From(\&Test::Deep::noneof);
	sub expect_num                  :Exported(all,expectations) :From(\&Test::Deep::num);
	sub expect_obj_isa              :Exported(all,expectations) :From(\&Test::Deep::obj_isa);
	sub expect_re                   :Exported(all,expectations) :From(\&Test::Deep::re);
	sub expect_ref_type             :Exported(all,expectations) :From(\&Test::Deep::reftype);
	sub expect_regexp_matches       :Exported(all,expectations) :From(\&Test::Deep::regexpmatches);
	sub expect_regexp_only          :Exported(all,expectations) :From(\&Test::Deep::regexponly);
	sub expect_regexpref            :Exported(all,expectations) :From(\&Test::Deep::regexpref);
	sub expect_regexpref_only       :Exported(all,expectations) :From(\&Test::Deep::regexprefonly);
	sub expect_scalarref            :Exported(all,expectations) :From(\&Test::Deep::scalref);
	sub expect_scalarref_only       :Exported(all,expectations) :From(\&Test::Deep::scalarrefonly);
	sub expect_set                  :Exported(all,expectations) :From(\&Test::Deep::set);
	sub expect_shallow              :Exported(all,expectations) :From(\&Test::Deep::shallow);
	sub expect_str                  :Exported(all,expectations) :From(\&Test::Deep::str);
	sub expect_subbag               :Exported(all,expectations) :From(\&Test::Deep::subbagof);
	sub expect_subbag_of            :Exported(all,expectations) :From(\&Test::Deep::subbagof);
	sub expect_subhash              :Exported(all,expectations) :From(\&Test::Deep::subhashof);
	sub expect_subhash_of           :Exported(all,expectations) :From(\&Test::Deep::subhashof);
	sub expect_subset               :Exported(all,expectations) :From(\&Test::Deep::subsetof);
	sub expect_subset_of            :Exported(all,expectations) :From(\&Test::Deep::subsetof);
	sub expect_superbag             :Exported(all,expectations) :From(\&Test::Deep::superbagof);
	sub expect_superbag_of          :Exported(all,expectations) :From(\&Test::Deep::superbagof);
	sub expect_superhash            :Exported(all,expectations) :From(\&Test::Deep::superhashof);
	sub expect_superhash_of         :Exported(all,expectations) :From(\&Test::Deep::superhashof);
	sub expect_superset             :Exported(all,expectations) :From(\&Test::Deep::supersetof);
	sub expect_superset_of          :Exported(all,expectations) :From(\&Test::Deep::supersetof);
	sub expect_true                 :Exported(all,expectations);
	sub expect_use_class            :Exported(all,asserts)      :From(\&Test::Deep::useclass);
	sub expect_value                :Exported(all,expectations) :Cmp_Builder(Test::YAFT::Cmp);
	sub explain                     :Exported(all,helpers)      :From(\&Test::More::explain);
	sub fail                        :Exported(all,asserts);
	sub got (&)                     :Exported(all,helpers);
	sub had_no_warnings             :Exported(all,asserts)      :From(\&Test::Warnings::had_no_warnings);
	sub ignore                      :Exported(all,expectations) :From(\&Test::Deep::ignore);
	sub it                          :Exported(all,asserts);
	sub nok                         :Exported(all,asserts);
	sub note                        :Exported(all,helpers)      :From(\&Test::More::note);
	sub ok                          :Exported(all,asserts);
	sub pass (;$)                   :Exported(all,asserts)      :From(\&Test::More::pass);
	sub plan                        :Exported(all,helpers)      :From(\&Test::More::plan);
	sub skip                        :Exported(all,helpers)      :From(\&Test::More::skip);
	sub subtest                     :Exported(all,helpers);
	sub test_deep_cmp               :Exportable(all,plumbings);
	sub test_frame (&)              :Exportable(all,plumbings);
	sub there                       :Exported(all,asserts)      :From(\&it);
	sub todo                        :Exported(all,helpers)      :From(\&Test::More::todo);
	sub todo_skip                   :Exported(all,helpers)      :From(\&Test::More::todo_skip);

	my $SINGLETON_ACT = 'Test::YAFT::act';

	sub _act_arrange;
	sub _act_dependencies;
	sub _act_singleton;
	sub _build_got;
	sub _it_params;
	sub _run_act;
	sub _run_coderef;
	sub _run_diag;

	sub _act_arrange {
		my ($params) = @_;

		proclaim $_->resolve
			for @{ $params->{arrange} // [] };

		proclaim s/^with_//r => $params->{$_}
			for grep m/^with_/, keys %$params;
	}

	sub _act_dependencies {
		my ($act, @dependencies) = @{ deduce $SINGLETON_ACT };

		return @dependencies;
	}

	sub _act_singleton {
		my ($act, @dependencies) = @{ deduce $SINGLETON_ACT };

		return $act;
	}

	sub _build_got {
		my ($params) = @_;

		return _run_act
			unless exists $params->{got};

		return _run_coderef ($params->{got})
			if Ref::Util::is_coderef ($params->{got});

		return +{
			lives_ok => 1,
			value    => $params->{got},
			error    => undef,
		};
	}

	sub _it_params {
		my %params;

		while (@_) {
			if (Scalar::Util::blessed ($_[0])) {
				$params{got} = shift and next
					if $_[0]->isa (Test::YAFT::Got::);
				push @{ $params{arrange} //= [] }, shift and next
					if $_[0]->isa (Test::YAFT::Arrange::);
				die "Ref ${\ ref $_[0] } not recognized";
			}

			my ($key, $value) = splice @_, 0, 2;

			push @{ $params{arrange} //= [] }, Test::YAFT::Arrange::->new (sub { $value }) and next
				if $key eq 'arrange';

			$params{$key} = $value;
		}

		return %params;
	}

	sub _run_act {
		my ($act, @dependencies) = @{ deduce $SINGLETON_ACT };
		my @missing = grep { ! try_deduce $_ } @dependencies;

		return {
			lives_ok => 0,
			value    => undef,
			error    => "Act dependencies not fultified: ${\ join ', ', sort @missing }",
		} if @missing;

		deduce _act_singleton;
	}

	sub _run_coderef {
		my ($builder, @args) = @_;

		my $result = { value => undef };
		$result->{lives_ok} = eval { $result->{value} = $builder->(@args); 1 };
		$result->{error} = $@;

		return $result;
	}

	sub _run_diag {
		my ($diag, $stack, $got) = @_;

		return
			unless $diag;

		return Test::More::diag ($diag->($stack, $got))
			if Ref::Util::is_coderef ($diag);

		return Test::More::diag (@$diag)
			if Ref::Util::is_arrayref ($diag);

		return Test::More::diag ($diag);
	}

	sub act (&;@) {
		my ($act, @dependencies) = @_;
		state $counter = 0;

		# As far as Context::Singleton doesn't support frame local contrive (yet)
		# we have to improvise
		# - singleton 'Test::YAFT::act' will contain name of frame specific singleton
		# - and that singleton will contain all dependencies

		my $singleton = "${SINGLETON_ACT}::${\ ++$counter }";

		contrive $singleton
			=> dep => \@dependencies
			=> as  => sub { _run_coderef ($act, @_) }
			;

		proclaim $SINGLETON_ACT => [ $singleton, @dependencies ];
	}

	sub arrange (&) {
		return Test::YAFT::Arrange::->new (@_);
	}

	sub expect_false {
		Test::Deep::bool (0);
	}

	sub expect_true {
		Test::Deep::bool (1);
	}

	sub fail {
		my ($title, %params) = @_;

		test_frame {
			it $title, diag => '', %params, got => 0, expect => expect_true;
		}
	}

	sub got (&) {
		Test::YAFT::Got->new (@_);
	}

	sub it {
		my ($title, @params) = @_;

		my %params = _it_params @params;

		my ($ok, $stack, $got, $expect);
		test_frame {
			_act_arrange (\ %params);
			my $result = _build_got (\ %params);

			return fail $title, diag => "Expected to live but died: $result->{error}"
				if ! $result->{lives_ok} && ! exists $params{throws};

			return fail $title, diag => "Expected to die by lives"
				if $result->{lives_ok} && exists $params{throws};

			($got, $expect) = $result->{lives_ok}
				? ($result->{value}, $params{expect})
				: ($result->{error}, $params{throws})
				;

			($ok, $stack) = Test::Deep::cmp_details ($got, $expect);

			return Test::More::ok ($ok, $title)
				if $ok
				|| defined $params{diag}
				|| $expect->$Safe::Isa::_isa (Test::Deep::Boolean::)
				;

			if ($expect->$Safe::Isa::_isa (Test::YAFT::Cmp::Complement::)) {
				Test::More::ok ($ok, $title);
				Test::More::diag (Test::Deep::deep_diag ($stack))
					unless $ok;
				return $ok;
			}

			Test::Differences::eq_or_diff $got, $expect, $title;
			Test::More::diag (Test::Deep::deep_diag ($stack))
				if ref $got || ref $expect;

			return;
		} or _run_diag ($params{diag}, $stack, $got);

		return $ok;
	}

	sub nok {
		my ($message, %params) = @_;

		test_frame {
			it $message, %params, expect => expect_false, diag => ''
		}
	}

	sub ok {
		my ($message, %params) = @_;

		test_frame {
			it $message, %params, expect => expect_true, diag => ''
		}
	}

	sub subtest {
		my ($title, $code) = @_;

		test_frame {
			Test::More::subtest $title, $code;
		};
	}

	sub test_deep_cmp {
		my (%methods) = @_;

		state $serial = 0;
		my $prefix = 'Test::Deep::Cmp::__ANON__::';

		my $class = $prefix . ++$serial;
		my $isa = delete $methods{isa} // 'Test::YAFT::Cmp';

		{
			my @isa = Ref::Util::is_arrayref ($isa) ? @$isa : ($isa);
			eval "require $_" for @isa;

			no strict 'refs';
			@{ "$class\::ISA" } = @isa;
		}

		Sub::Install::install_sub ({ into => $class, as => $_, code => $methods{$_} })
			for keys %methods;

		return $class;
	}

	sub test_frame (&) {
		my ($code) = @_;

		# 1 - caller sub context
		# 2 - this sub context
		# 3 - frame
		# 4 - code arg context
		local $Test::Builder::Level = $Test::Builder::Level + 4;

		&frame ($code);
	}

	1;
}
$Test::YAFT::VERSION = '1.0.2';;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::YAFT - Yet another testing framework

=head1 SYNOPSIS

	use Test::YAFT;

	it "should pass this test"
		=> got    => scalar do { ... }
		=> expect => $expected_value
		;

=head1 DISCLAIMER

Please accept the fact that I'm not English native speaker so this documentation
may contain improper grammar or wording making it harder to understand.

If you encounter such place, please visit project's issue tracking.

=head1 DESCRIPTION

This module combines features of multiple test libraries providing
its own, BDD inspired, Context oriented, testing approach.

=head1 GLOSSARY

=over

=item assert

Assert function performs actual value comparison.

=item expectation

Expectation function provides object (L<Test::Deep::Cmp>) describing
expected value.

=item plumbing

Similar concept to git, plumbing functions are used to build
higher level asserts, expectations, and/or tools.

=back

=head1 Test::YAFT AND OTHER LIBRARIES

Please read following documentation how are other test libraries
mapped into L<Test::YAFT> workflow.

=over

=item L<Test::YAFT::Test::Deep>

=item L<Test::YAFT::Test::Exception>

=item L<Test::YAFT::Test::More>

=item L<Test::YAFT::Test::Spec>

=item L<Test::YAFT::Test::Warnings>

=back

This document contains reference manual. If you want some kind of tutorial,
please visit L<Test::YAFT::Introduction> as well.

=head1 EXPORTED SYMBOLS

This module exports symbols using L<Exporter::Tiny>.

=head2 Asserts

	use Test::YAFT qw[ :asserts ];

Assert functions are exported by default.

Every assert accepts (if any) test message as a first (positional) parameter,
with restof parameters using named approach.

When assert performs multiple expectations internally, it always reports
as one, using provided test message, failing early.

Named parameters are provided either via key/value pairs

	ok "test title"
		=> got => $value
		;

or via builder functions

	ok "test title"
		=> got { build got }
		;

Coding style note: I suggest to use coding style as presented in all examples,
with one parameter per line, leading with fat comma.

=head3 fail

	return fail 'what failed';
	return fail 'what failed'
		=> diag => "diagnostic message"
		;
	return fail 'what failed'
		=> diag => sub { "diagnostic message" }
		;

Likewise L<Test::More/fail> it also always fails, but it also accepts
additional parameter - diagnostic message to show.

When diagnostic message is a CODEREF, it is executed and its result is treated
as list of diagnostic messages (passed to C<diag>)

=head3 had_no_warnings

	had_no_warnings;
	had_no_warnings 'title';

Reexported from L<Test::Warnings>

=head3 it

	it "should be ..."
		=> got    => ...
		=> expect => ...
		;

Basic test primitive, used by all other test functions.
It uses L<Test::Deep>'s C<cmp_deeply> to compare values.

In addition to C<Test::Deep>'s stack also uses L<Test::Difference> to report
differences when failed.

When expected value is L<Test::Deep::Bool> then it uses L<Test::More>'s C<ok>.

Accepted named(-like) parameters:

=over

=item arrange

	it "should ..."
		=> arrange { foo => "bar" }
		=> arrange { bar => "baz" }
		;

C<arrange { }> blocks are evaluated in context of C<it>-local frame
before resolving value under test (C<got { }>).

C<arrange { }> blocks are always evaluated, even when value under test
is provided as an exact value.

=item diag

Custom diagnostic message, printed out in case of failure.

When specified no other diagnostic message is printed.

Can be string, arrayref of strings, or coderef returning strings.

Coderef gets two parameters - Test::Deep stack and value under test.

=item expect

Expected value.

When specified and C<got { }> block is used, additional expectation that it
didn't die is executed before any other comparison.

=item got

Value under test.

When C<got { }> block is used, it is evaluated and its error status is checked
before actual comparison.

=item throws

Expected error.

When specified and C<got { }> block is used, additional expectation that it
did die is executed before any other comparison.

When both C<expect> and C<throws> parameters are specified, C<throws> takes precedence.

See also L<Test::YAFT::Test::Exception>.

=back

=head3 nok

	nok "shouldn't be ..."
		=> got    => ...
		;

Simple shortcut to expect value behaving like boolean false.

=head3 ok

	ok "should be ..."
		=> got    => ...
		;


Simple shortcut to expect value behaving like boolean true.

=head3 pass

	pass 'what passed';

Reexported from L<Test::More>

=head3 there

	there "should be ..."
		=> got    => ...
		=> expect => ...
		;

Alias for C<it>, providing convenient word to form meaningful English sentence

=head2 Expectations

Every expectation returns L<Test::Deep::Cmp> object.

=head3 expect_all

Reexported L<Test::Deep/all>.

=head3 expect_any

Reexported L<Test::Deep/any>.

=head3 expect_array

Reexported L<Test::Deep/array>.

=head3 expect_array_each

Reexported L<Test::Deep/array_each>.

=head3 expect_array_elements_only

Reexported L<Test::Deep/arrayelementsonly>.

=head3 expect_array_length

Reexported L<Test::Deep/arraylength>.

=head3 expect_array_length_only

Reexported L<Test::Deep/arraylengthonly>.

=head3 expect_bag

Reexported L<Test::Deep/bag>.

=head3 expect_blessed

Reexported L<Test::Deep/blessed>.

=head3 expect_bool

Reexported L<Test::Deep/bool>.

=head3 expect_code

Reexported L<Test::Deep/code>.

=head3 expect_compare

	it "should not exceed maximum value"
		=> got    => $got
		=> expect => expect_compare ('<=', $max)
		;

Similar to L<Test::More/cmp_ok> but provided as an expectation instead
so it can be combined with other L<Test::Deep>-based expectations.

=head3 expect_complement_to

	it "should be a boring number"
		=> got    => $got
		=> expect => expect_complement_to (42)
		;

Negative expectation.

Usually it's easier to use overloaded complement operators C<!> or C<~>.

=head3 expect_false

Boolean expectation.

=head3 expect_hash

Reexported L<Test::Deep/hash>.

=head3 expect_hash_each

Reexported L<Test::Deep/hash_each>.

=head3 expect_hash_keys

Reexported L<Test::Deep/hashkeys>.

=head3 expect_hash_keys_only

Reexported L<Test::Deep/hashkeysonly>.

=head3 expect_isa

Reexported L<Test::Deep/Isa>.
Instance or inheritance expectation.

=head3 expect_listmethods

Reexported L<Test::Deep/listmethods>.

=head3 expect_methods

Reexported L<Test::Deep/methods>.

=head3 expect_no_class

Reexported L<Test::Deep/noclass>.

=head3 expect_none

Reexported L<Test::Deep/none>.

=head3 expect_none_of

Reexported L<Test::Deep/noneof>.

=head3 expect_num

Reexported L<Test::Deep/num>.

=head3 expect_obj_isa

Reexported L<Test::Deep/obj_isa>.

=head3 expect_re

Reexported L<Test::Deep/re>.

=head3 expect_ref_type

Reexported L<Test::Deep/reftype>.

=head3 expect_regexp_matches

Reexported L<Test::Deep/regexpmatches>.

=head3 expect_regexp_only

Reexported L<Test::Deep/regexponly>.

=head3 expect_regexpref

Reexported L<Test::Deep/regexpref>.

=head3 expect_regexpref_only

Reexported L<Test::Deep/regexprefonly>.

=head3 expect_scalarref

Reexported L<Test::Deep/scalarref>.

=head3 expect_scalarrefonly

Reexported L<Test::Deep/scalarrefonly>.

=head3 expect_set

Reexported L<Test::Deep/set>.

=head3 expect_shallow

Reexported L<Test::Deep/shallow>.

=head3 expect_str

Reexported L<Test::Deep/str>.

=head3 expect_subbag

Reexported L<Test::Deep/subbagof>.

=head3 expect_subbag_of

Reexported L<Test::Deep/subbagof>.

=head3 expect_subhash

Reexported L<Test::Deep/subhashof>.

=head3 expect_subhash_of

Reexported L<Test::Deep/subhashof>.

=head3 expect_subset

Reexported L<Test::Deep/subsetof>.

=head3 expect_subset_of

Reexported L<Test::Deep/subsetof>.

=head3 expect_superbag

Reexported L<Test::Deep/superbagof>.

=head3 expect_superbag_of

Reexported L<Test::Deep/superbagof>.

=head3 expect_superhash

Reexported L<Test::Deep/superhashof>.

=head3 expect_superhash_of

Reexported L<Test::Deep/superhashof>.

=head3 expect_superset

Reexported L<Test::Deep/supersetof>.

=head3 expect_superset_of

Reexported L<Test::Deep/supersetof>.

=head3 expect_true

Boolean expectation.

=head3 expect_use_class

Reexported L<Test::Deep/useclass>.

=head3 expect_value

	=> expect => expect_value (42)

Wraps any value as an expectation.

=head3 ignore

Reexported L<Test::Deep/ignore>.

=head2 Helper Functions

	use Test::YAFT qw[ :helpers ];

Helper functions are exported by default.

Functions helping to organize your tests.

=head3 BAIL_OUT

Reexported L<Test::More/BAIL_OUT>

=head3 arrange

	arrange { foo => "bar" };

	it "should ..."
		=> arrange { foo => "bar2" }
		=> got { $foo->method (deduce 'foo') }
		=> expect => ...
		;

Arrange block is treated as a function providing arguments for L<Context::Singleton>'s
C<proclaim>.

Arrange block returns a guard object, which is evaluated in frame valid at the
time of evaluation (timely evaluation is responsibility of C<it>).

When C<arrange { }> is called in void context, it is evaluated immediately.

Validity of values follows L<Context::Singleton> rules, so for example

	# This is available globally
	arrange { foo => "global value" };

	subtest "subtest" => sub {
		# This is available in scope of subtest (it creates its own frame)
		arrange { foo => "subtest local" };

		# This is available only in scope of 'it' (ie, insite got { })
		it "should ..."
			=> got { ... }
			=> arrange { foo => "assert local" }
			;
	};

=head3 diag

Reexported L<Test::More/diag>

=head3 done_testing

Reexported L<Test::More/done_testing>

=head3 explain

Reexported L<Test::More/explain>

=head3 got

Can be used to specify code to build test value or to test that given code
should / shouldn't throw an exception.

	it "should die"
		=> got { $foo->do_something }
		=> throws => expect_obj_isa (...)
		;

When used, C<it> always checks error status first before checking provided
expectations.

=head3 note

Reexported L<Test::More/note>

=head3 plan

Reexported L<Test::More/plan>

=head3 skip

Reexported L<Test::More/skip>

=head3 subtest

	subtest "title" => sub {
		...;
	}

Similar to L<Test::More/subtest> but also creates new L<Context::Singleton>
frame for each subtest.

=head3 todo

Reexported L<Test::More/todo>

=head3 todo_skip

Reexported L<Test::More/todo_skip>

=head2 Plumbing Functions

	use Test::YAFT qw[ :plumbings ];

Functions helping writing your custom asserts, expectations, and/or tools.
Plumbing functions are not exported by default.

=head3 cmp_details

	use Test::YAFT qw[ cmp_details ];
	my ($ok, $stack) = cmp_details ($a, $b);

Reexported L<Test::Deep/cmp_details>.

=head3 deep_diag

	use Test::YAFT qw[ deep_diag ];
	deep_diag ($stack);

Reexported L<Test::Deep/deep_diag>.

=head3 eq_deeply

	use Test::YAFT qw[ eq_deeply ];
	if (eq_deeply ($a, $b)) {
	}

Reexported L<Test::Deep/eq_deeply>.

=head3 test_deep_cmp

Creates "anonymous" (as far as Perl supports) L<Test::Deep> comparator class.
Returns created class name.

Typical usage

	sub expect_foo {
		state $class = test_deep_cmp (
			isa => ...,
			descend => ...,
			renderGot => ...,
		);

		$class->new (@_);
	}


Accepts named arguments

=over

=item isa => <PACKAGE>

Parent class, default: L<Test::YAFT::Cmp>.

=item <METHOD> => <CODEREF>

Every other named parameter is treated as a method name to install into created namespace.

=back

=head3 test_frame (&)

	use Test::YAFT qw[ test_frame ];
	sub my_assert {
		test_frame {
			...
		};
	}

Utility function to populate required boring details like

=over

=item adjusting L<Test::Builder/level>

=item create L<Context::Singleton/frame>

=back

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

Test::YAFT distribution is distributed under Artistic Licence 2.0.

=cut

