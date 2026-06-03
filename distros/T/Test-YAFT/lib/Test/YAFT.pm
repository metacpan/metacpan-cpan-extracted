
use v5.14;
use warnings;

use Syntax::Construct qw (package-block package-version);

package Test::YAFT v1.0.3 {
	use parent qw (Exporter::Tiny);

	use Context::Singleton;
	use Ref::Util qw ();
	use Safe::Isa qw ();
	use Scalar::Util qw ();
	use Sub::Install qw ();
	use Sub::Override qw ();

	use Test::Deep qw ();
	use Test::Differences qw ();
	use Test::More     v0.970 qw ();
	use Test::Warnings v0.038 qw (:no_end_test !done_testing);

	use Test::YAFT::Argument;
	use Test::YAFT::Argument::Arrange;
	use Test::YAFT::Argument::Got;
	use Test::YAFT::Attributes;
	use Test::YAFT::Cmp;
	use Test::YAFT::Cmp::Complement;
	use Test::YAFT::Dumper;

	# v5.14 forward prototype declaration to prevent warnings from attributes
	sub act (&;@);
	sub arrange (&);
	sub got (&);
	sub had_no_warnings (;$);
	sub pass ($);

	sub act (&;@)                       :Util;
	sub arrange (&)                     :Util(Test::YAFT::Argument::Arrange::);
	sub assume                          :Assumption(\&_test_yaft_assumption);
	sub BAIL_OUT                        :Util(\&Test::More::BAIL_OUT);
	sub cmp_details                     :Foundation(\&Test::Deep::cmp_details);
	sub deep_diag                       :Foundation(\&Test::Deep::deep_diag);
	sub diag                            :Util(\&Test::More::diag);
	sub done_testing                    :Util(\&Test::More::done_testing);
	sub eq_deeply                       :Foundation(\&Test::Deep::eq_deeply);
	sub expect_all                      :Expectation(\&Test::Deep::all);
	sub expect_any                      :Expectation(\&Test::Deep::any);
	sub expect_array                    :Expectation(\&Test::Deep::array);
	sub expect_array_each               :Expectation(\&Test::Deep::array_each);
	sub expect_array_elements_only      :Expectation(\&Test::Deep::arrayelementsonly);
	sub expect_array_length             :Expectation(\&Test::Deep::arraylength);
	sub expect_array_length_only        :Expectation(\&Test::Deep::arraylengthonly);
	sub expect_bag                      :Expectation(\&Test::Deep::bag);
	sub expect_blessed                  :Expectation(\&Test::Deep::blessed);
	sub expect_bool                     :Expectation(\&Test::Deep::bool);
	sub expect_code                     :Expectation(\&Test::Deep::code);
	sub expect_compare                  :Expectation(Test::YAFT::Cmp::Compare);
	sub expect_complement               :Expectation(Test::YAFT::Cmp::Complement);
	sub expect_false                    :Expectation(\&Test::Deep::bool, 0);
	sub expect_hash                     :Expectation(\&Test::Deep::hash);
	sub expect_hash_each                :Expectation(\&Test::Deep::hash_each);
	sub expect_hash_keys                :Expectation(\&Test::Deep::hashkeys);
	sub expect_hash_keys_only           :Expectation(\&Test::Deep::hashkeysonly);
	sub expect_isa                      :Expectation(\&Test::Deep::Isa);
	sub expect_listmethods              :Expectation(\&Test::Deep::listmethods);
	sub expect_methods                  :Expectation(\&Test::Deep::methods);
	sub expect_no_class                 :Expectation(\&Test::Deep::noclass);
	sub expect_none                     :Expectation(\&Test::Deep::none);
	sub expect_none_of                  :Expectation(\&Test::Deep::noneof);
	sub expect_num                      :Expectation(\&Test::Deep::num);
	sub expect_obj_isa                  :Expectation(\&Test::Deep::obj_isa);
	sub expect_re                       :Expectation(\&Test::Deep::re);
	sub expect_ref_type                 :Expectation(\&Test::Deep::reftype);
	sub expect_regexp_matches           :Expectation(\&Test::Deep::regexpmatches);
	sub expect_regexp_only              :Expectation(\&Test::Deep::regexponly);
	sub expect_regexpref                :Expectation(\&Test::Deep::regexpref);
	sub expect_regexpref_only           :Expectation(\&Test::Deep::regexprefonly);
	sub expect_scalarref                :Expectation(\&Test::Deep::scalref);
	sub expect_scalarref_only           :Expectation(\&Test::Deep::scalarrefonly);
	sub expect_set                      :Expectation(\&Test::Deep::set);
	sub expect_shallow                  :Expectation(\&Test::Deep::shallow);
	sub expect_str                      :Expectation(\&Test::Deep::str);
	sub expect_subbag                   :Expectation(\&Test::Deep::subbagof);
	sub expect_subbag_of                :Expectation(\&Test::Deep::subbagof);
	sub expect_subhash                  :Expectation(\&Test::Deep::subhashof);
	sub expect_subhash_of               :Expectation(\&Test::Deep::subhashof);
	sub expect_subset                   :Expectation(\&Test::Deep::subsetof);
	sub expect_subset_of                :Expectation(\&Test::Deep::subsetof);
	sub expect_superbag                 :Expectation(\&Test::Deep::superbagof);
	sub expect_superbag_of              :Expectation(\&Test::Deep::superbagof);
	sub expect_superhash                :Expectation(\&Test::Deep::superhashof);
	sub expect_superhash_of             :Expectation(\&Test::Deep::superhashof);
	sub expect_superset                 :Expectation(\&Test::Deep::supersetof);
	sub expect_superset_of              :Expectation(\&Test::Deep::supersetof);
	sub expect_true                     :Expectation(\&Test::Deep::bool, 1);
	sub expect_use_class                :Expectation(\&Test::Deep::useclass);
	sub expect_value                    :Expectation(Test::YAFT::Cmp);
	sub explain                         :Util(\&Test::More::explain);
	sub fail                            :Assumption;
	sub got (&)                         :Util(Test::YAFT::Argument::Got::);
	sub had_no_warnings (;$)            :Assumption(\&Test::Warnings::had_no_warnings);
	sub ignore                          :Expectation(\&Test::Deep::ignore);
	sub it                              :Assumption(\&_test_yaft_assumption);
	sub nok                             :Assumption;
	sub note                            :Util(\&Test::More::note);
	sub ok                              :Assumption;
	sub pass ($)                        :Assumption(\&Test::More::pass);
	sub plan                            :Util(\&Test::More::plan);
	sub skip                            :Util(\&Test::More::skip);
	sub subtest                         :Util;
	sub test_deep_cmp                   :Foundation;
	sub test_frame (&)                  :Foundation;
	sub there                           :Assumption(\&_test_yaft_assumption);
	sub todo                            :Util(\&Test::More::todo);
	sub todo_skip                       :Util(\&Test::More::todo_skip);

	my $SINGLETON_ACT = q (Test::YAFT::act);

	sub _act_arrange;
	sub _act_dependencies;
	sub _act_singleton;
	sub _build_got;
	sub _run_act;
	sub _run_coderef;
	sub _run_diag;
	sub _test_yaft_assumption_args;

	sub _act_arrange {
		my ($args) = @_;

		proclaim $_->resolve
			for @{ $args->{arrange} // [] };
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
		my ($args) = @_;

		return _run_act
			unless exists $args->{got};

		return _run_coderef ($args->{got}->{code})
			if $args->{got}->$Safe::Isa::_isa (Test::YAFT::Argument::Got::)
			;

		return _run_coderef ($args->{got})
			if Ref::Util::is_coderef ($args->{got});

		return +{
			lives_ok => 1,
			value    => $args->{got},
			error    => undef,
		};
	}

	sub _run_act {
		my ($act, @dependencies) = @{ deduce $SINGLETON_ACT };
		my @missing = grep { ! try_deduce $_ } @dependencies;

		return {
			lives_ok => 0,
			value    => undef,
			error    => qq (Act dependencies not fulfilled: ${\ join q (, ), sort @missing }),
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

	sub _test_yaft_assumption {
		my ($title, @args) = @_;

		my %args = _test_yaft_assumption_args @args;

		my $guard = Sub::Override::->new (
			q (Data::Dumper::Dumper) => \ &Test::YAFT::Dumper::Dumper,
		);

		my ($ok, $stack, $got, $expect);
		test_frame {
			_act_arrange (\ %args);
			my $result = _build_got (\ %args);

			my $expected_to_live = ! exists $args{throws};

			return fail $title, diag => $expected_to_live
				? qq (Expected to live but died: $result->{error})
				: q  (Expected to die by lives)
				if $expected_to_live xor $result->{lives_ok}
				;

			($got, $expect) = $result->{lives_ok}
				? ($result->{value}, $args{expect})
				: ($result->{error}, $args{throws})
				;

			($ok, $stack) = Test::Deep::cmp_details ($got, $expect);

			return Test::More::ok ($ok, $title)
				if $ok
				|| defined $args{diag}
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
		} or _run_diag ($args{diag}, $stack, $got);

		return $ok;
	}

	sub _test_yaft_assumption_args {
		my %args;

		while (@_) {
			my $key = shift;

			if (Scalar::Util::blessed ($key)) {
				$key->set_argument (\ %args), next
					if $key->isa (Test::YAFT::Argument::)
					;

				die qq (Ref ${\ ref $_[0] } not recognized);
			}

			my $value = shift;

			if (my ($property) = $key =~ m (^ with [_] (.*) $)x) {
				unshift @_, arrange { $property => $value };
				next;
			}

			# TODO: what should be good syntax here ?
			#push @{ $args{arrange} //= [] }, Test::YAFT::Arrange::->new (sub { $value }) and next
			#	if $key eq q (arrange);

			$args{$key} = $value;
		}

		return %args;
	}

	sub act (&;@) {
		my ($act, @dependencies) = @_;
		state $counter = 0;

		# As far as Context::Singleton doesn't support frame local contrive (yet)
		# we have to improvise
		# - singleton 'Test::YAFT::act' will contain name of frame specific singleton
		# - and that singleton will contain all dependencies

		my $singleton = qq (${SINGLETON_ACT}::${\ ++$counter });

		contrive $singleton
			=> dep => \@dependencies
			=> as  => sub { _run_coderef ($act, @_) }
			;

		proclaim $SINGLETON_ACT => [ $singleton, @dependencies ];
	}

	sub fail {
		my ($title, %args) = @_;

		test_frame {
			_test_yaft_assumption $title,
				diag => q (),
				%args,
				got => 0,
				expect => expect_true,
				;
		}
	}

	sub nok {
		my ($message, %args) = @_;

		test_frame {
			_test_yaft_assumption $message,
				%args,
				expect => expect_false,
				diag   => q (),
				;
		}
	}

	sub ok {
		my ($message, %args) = @_;

		test_frame {
			_test_yaft_assumption $message,
				%args,
				expect => expect_true,
				diag   => q (),
				;
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
		my $prefix = q (Test::Deep::Cmp::__ANON__::);

		my $class = $prefix . ++$serial;
		my $isa = delete $methods{isa} // q (Test::YAFT::Cmp);

		{
			my @isa = Ref::Util::is_arrayref ($isa) ? @$isa : ($isa);
			eval qq (require $_) for @isa;

			no strict q (refs);
			@{ qq ($class\::ISA) } = @isa;
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
};
