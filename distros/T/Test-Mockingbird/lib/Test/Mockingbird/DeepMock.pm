package Test::Mockingbird::DeepMock;

use strict;
use warnings;

use Carp      qw(croak);
use Exporter  'import';
use Test::Mockingbird        ();
use Test::Mockingbird::TimeTravel ();
use Test::More ();

our @EXPORT_OK = qw(deep_mock);

=head1 NAME

Test::Mockingbird::DeepMock - Declarative structured mocking and spying for Perl tests

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use Test::Mockingbird::DeepMock qw(deep_mock);

    deep_mock(
        {
            mocks => [
                { target => 'MyApp::greet', type => 'mock', with => sub { 'hi' } },
                { target => 'MyApp::double', type => 'spy', tag => 'double_spy' },
            ],
            expectations => [
                { tag => 'double_spy', calls => 2 },
            ],
        },
        sub {
            is MyApp::greet(), 'hi', 'greet mocked';
            MyApp::double(2);
            MyApp::double(3);
        }
    );

=head1 DESCRIPTION

C<Test::Mockingbird::DeepMock> provides a declarative, data-driven way to
describe mocking, spying, injection, and expectations in Perl tests.

Instead of scattering C<mock>, C<spy>, and C<restore_all> calls throughout
your test code, DeepMock lets you define a complete mocking plan in a single
hashref, then executes your test code under that plan.

=head1 LIMITATIONS

=over 4

=item Nested deep_mock scopes are not supported

C<deep_mock> calls C<restore_all()> on exit, which removes every active mock.
A nested C<deep_mock> call will cause the inner exit to also tear down the
outer mocks.

=item inject type in mocks list

The C<inject> mock type delegates to C<Test::Mockingbird::inject()>. Because
C<inject()> builds a sub that returns the C<with> value verbatim, passing a
coderef via C<with> stores the coderef itself; it is not called on each
access. To inject a factory, wrap it explicitly.

=back

=head1 PLAN STRUCTURE

=head2 C<mocks>

ArrayRef of mock specs. Each entry:

    {
        target => 'Package::method',
        type   => 'mock' | 'spy' | 'inject',
        with   => sub { ... },
        tag    => 'identifier',
    }

=head2 C<expectations>

ArrayRef of expectation specs. Each entry:

    {
        tag        => 'spy_tag',
        calls      => $n,
        args_like  => [ [qr/pat1/, qr/pat2/], ... ],
        args_eq    => [ ['exact', 'args'],    ... ],
        args_deeply => [ [$struct],           ... ],
        never      => 1,
        order      => [ 'A::m1', 'B::m2' ],
    }

The C<order> key is processed after all per-spy expectations and does not
require a C<tag>.

=head2 C<globals>

Optional:

    globals => { restore_on_scope_exit => 1 }

=head2 C<time>

Optional time-travel plan applied before mocks are installed:

    time => {
        freeze  => '2025-01-01T00:00:00Z',
        travel  => '2025-01-03T00:00:00Z',
        advance => [ 2 => 'minutes' ],
        rewind  => [ 1 => 'hour'    ],
    }

=head1 TROUBLESHOOTING

=head2 "Not enough arguments for deep_mock"

DeepMock uses C<($$)> prototype. Use C<deep_mock( {...}, sub { ... } )>.

=head2 My mocks are not restored

Check C<globals => { restore_on_scope_exit => 0 }> has not been set.

=head1 METHODS

=head2 deep_mock

Run a code block with a set of mocks and expectations applied.

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict schema)

    $plan -- HashRef with keys: mocks, expectations, globals, time
    $code -- CodeRef

=head4 Output (Returns::Set schema)

    returns: whatever $code returns (context-sensitive)

=head3 MESSAGES

  "deep_mock expects a HASHREF plan" -- first arg is not a hashref

=head3 FORMAL SPECIFICATION

    deep_mock ≙
      ∀ plan : HashRef; code : CodeRef •
        pre  ref(plan) = 'HASH'
        post apply_time(plan.time)
             ∧ install_mocks(plan.mocks)
             ∧ result = code()
             ∧ check_expectations(plan.expectations)
             ∧ restore_all()

=head3 PSEUDOCODE

    validate plan is HASH
    apply time plan if present
    install each mock/spy/inject from plan.mocks, building %handles
    capture wantarray context
    eval { run $code }
    run expectations against %handles
    restore all mocks (unless restore_on_scope_exit => 0)
    restore time state
    re-croak any exception from $code
    return $code's result in correct context

=cut

sub deep_mock {
	my ($plan, $code) = @_;

	croak 'deep_mock expects a HASHREF plan' unless ref $plan eq 'HASH';

	my %handles;

	_apply_time_plan($plan->{time});

	_install_mocks($plan->{mocks} // [], \%handles);

	# Preserve the caller's context through the eval block
	my $ctx = wantarray;
	my (@list_ret, $scalar_ret, $err);

	{
		local $@;
		if ($ctx) {
			@list_ret   = eval { $code->() };
		} elsif (defined $ctx) {
			$scalar_ret = eval { $code->() };
		} else {
			eval { $code->() };
		}
		$err = $@;
	}

	_run_expectations($plan->{expectations} // [], \%handles);

	my $auto_restore = !exists $plan->{globals}{restore_on_scope_exit}
		|| $plan->{globals}{restore_on_scope_exit};

	Test::Mockingbird::restore_all()           if $auto_restore;
	Test::Mockingbird::TimeTravel::restore_all();

	croak $err if $err;

	return $ctx ? @list_ret : $scalar_ret;
}

# _normalize_target -- Private
#
# Purpose:      Delegate to Test::Mockingbird::_parse_target.  Kept here as
#               a thin wrapper so that white-box tests calling
#               Test::Mockingbird::DeepMock::_normalize_target() continue to
#               work without requiring updates to those tests.
# Entry:        $target -- Str, 'Pkg::method' or ('Pkg', 'method')
# Exit:         ($package, $method)
# Side effects: none
sub _normalize_target {
	return Test::Mockingbird::_parse_target(@_);
}

# _install_mocks -- Private
#
# Purpose:      Install each mock/spy/inject described in the plan and
#               record spy handles in %handles for later expectation checks.
# Entry:        $mocks   -- ArrayRef of mock spec hashrefs
#               $handles -- HashRef to populate with spy/guard handles
# Exit:         undef
# Side effects: Modifies symbol tables of target packages.
#               Populates $handles.
sub _install_mocks {
	my ($mocks, $handles) = @_;

	my @installed;

	for my $m (@$mocks) {
		my $target = $m->{target}
			or croak 'mock entry missing target';

		my ($pkg, $method) = _normalize_target($target);
		my $full   = "${pkg}::${method}";
		my $type   = $m->{type} // 'mock';

		if ($type eq 'mock') {
			croak "mock type requires 'with' coderef"
				unless defined $m->{with} && ref $m->{with} eq 'CODE';

			Test::Mockingbird::mock($pkg, $method, $m->{with});
			$handles->{ $m->{tag} }{guard} = 1 if $m->{tag};

		} elsif ($type eq 'spy') {
			my $spy = Test::Mockingbird::spy($pkg, $method);
			$handles->{ $m->{tag} }{spy} = $spy if $m->{tag};

		} elsif ($type eq 'inject') {
			Test::Mockingbird::inject($pkg, $method, $m->{with});
			$handles->{ $m->{tag} }{inject} = 1 if $m->{tag};

		} else {
			croak "Unknown mock type '$type' for target '$target'";
		}

		push @installed, $full;
	}

	return @installed;
}

# _run_expectations -- Private
#
# Purpose:      Validate recorded spy calls against the plan's expectations.
#               Handles: calls, args_like, args_eq, args_deeply, never, order.
# Entry:        $exps    -- ArrayRef of expectation hashrefs
#               $handles -- HashRef populated by _install_mocks
# Exit:         undef
# Side effects: Emits TAP via Test::More.  Croaks on missing tag or spy.
sub _run_expectations {
	my ($exps, $handles) = @_;

	for my $exp (@$exps) {
		# order-only entries (no tag) are handled in the second pass below
		next if exists $exp->{order} && !exists $exp->{tag};

		my $tag = $exp->{tag}
			or croak 'expectation missing tag';

		my $spy = $handles->{$tag}{spy}
			or croak "no spy handle for tag '$tag'";

		my @calls = $spy->();   # [ full_method, @args ]

		# ---- call count -----------------------------------------------
		if (defined $exp->{calls}) {
			Test::More::is(scalar @calls, $exp->{calls},
				"DeepMock: calls for $tag");
		}

		# ---- args_like (regex matching) --------------------------------
		if (my $args_like = $exp->{args_like}) {
			for my $i (0 .. $#$args_like) {
				my $patterns = $args_like->[$i];
				my $call     = $calls[$i] // [];
				my @args     = @{$call}[1 .. $#$call];
				for my $j (0 .. $#$patterns) {
					my $re = $patterns->[$j];
					Test::More::like($args[$j],
						ref $re ? $re : qr/$re/,
						"DeepMock: arg $j call $i of $tag (args_like)");
				}
			}
		}

		# ---- args_eq (exact matching) ----------------------------------
		if (my $args_eq = $exp->{args_eq}) {
			for my $i (0 .. $#$args_eq) {
				my $expected = $args_eq->[$i];
				my $call     = $calls[$i] // [];
				my @args     = @{$call}[1 .. $#$call];
				for my $j (0 .. $#$expected) {
					Test::More::is($args[$j], $expected->[$j],
						"DeepMock: arg $j call $i of $tag (args_eq)");
				}
			}
		}

		# ---- args_deeply (structural) ----------------------------------
		if (my $args_deeply = $exp->{args_deeply}) {
			require Test::Deep;
			for my $i (0 .. $#$args_deeply) {
				my $expected = $args_deeply->[$i];
				my $call     = $calls[$i] // [];
				my @args     = @{$call}[1 .. $#$call];
				for my $j (0 .. $#$expected) {
					Test::Deep::cmp_deeply($args[$j], $expected->[$j],
						"DeepMock: arg $j call $i of $tag (args_deeply)");
				}
			}
		}

		# ---- never (assert zero calls) ---------------------------------
		if ($exp->{never}) {
			Test::More::is(scalar @calls, 0, "DeepMock: $tag was never called");
		}
	}

	# Second pass: process cross-method order expectations (no tag required)
	for my $exp (@$exps) {
		next unless exists $exp->{order};
		Test::Mockingbird::assert_call_order(@{ $exp->{order} });
	}

	return;
}

# _apply_time_plan -- Private
#
# Purpose:      Apply a time-travel plan from the deep_mock spec before
#               installing mocks. All keys are optional.
# Entry:        $time -- HashRef or undef
# Exit:         undef
# Side effects: Activates Test::Mockingbird::TimeTravel if any key is set.
sub _apply_time_plan {
	my $time = $_[0];
	return unless $time && ref $time eq 'HASH';

	Test::Mockingbird::TimeTravel::freeze_time($time->{freeze})
		if exists $time->{freeze};

	Test::Mockingbird::TimeTravel::travel_to($time->{travel})
		if exists $time->{travel};

	if (exists $time->{advance}) {
		my ($amount, $unit) = @{ $time->{advance} };
		Test::Mockingbird::TimeTravel::advance_time($amount, $unit);
	}

	if (exists $time->{rewind}) {
		my ($amount, $unit) = @{ $time->{rewind} };
		Test::Mockingbird::TimeTravel::rewind_time($amount, $unit);
	}

	return;
}

=head1 SUPPORT

Please report bugs at L<https://github.com/nigelhorne/Test-Mockingbird/issues>.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<Test::Mockingbird>

=item * L<Test::Mockingbird::Async>

=item * L<Test::Mockingbird::TimeTravel>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Test-Mockingbird>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to GPL2 licence terms.

=cut

1;
