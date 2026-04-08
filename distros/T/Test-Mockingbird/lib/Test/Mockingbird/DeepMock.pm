package Test::Mockingbird::DeepMock;

use strict;
use warnings;

use Exporter 'import';
use Carp qw(croak);
use Test::Mockingbird ();
use Test::Mockingbird::TimeTravel ();
use Test::More ();

our @EXPORT_OK = qw(deep_mock);

=head1 NAME

Test::Mockingbird::DeepMock - Declarative, structured mocking and spying for Perl tests

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Test::Mockingbird::DeepMock qw(deep_mock);

    {
        package MyApp;
        sub greet  { "hello" }
        sub double { $_[1] * 2 }
    }

    deep_mock(
        {
            mocks => [
                {
                    target => 'MyApp::greet',
                    type   => 'mock',
                    with   => sub { "mocked" },
                }, {
                    target => 'MyApp::double',
                    type   => 'spy',
                    tag    => 'double_spy',
                },
            ], expectations => [
                {
                    tag   => 'double_spy',
                    calls => 2,
                },
            ],
        },
        sub {
            is MyApp::greet(), 'mocked', 'greet() was mocked';

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

This produces tests that are:

=over 4

=item * easier to read

=item * easier to maintain

=item * easier to extend

=item * easier to reason about

=back

DeepMock is built on top of L<Test::Mockingbird>, adding structure,
expectations, and a clean DSL.

=head1 WHY DEEP MOCK?

Traditional mocking in Perl tends to be:

=over 4

=item * imperative

=item * scattered across the test body

=item * difficult to audit

=item * easy to forget to restore

=back

DeepMock solves these problems by letting you declare everything up front:

    deep_mock(
        {
            mocks        => [...],
            expectations => [...],
        },
        sub { ... }
    );

This gives you:

=over 4

=item * a single place to see all mocks and spies

=item * automatic restore of all mocks

=item * structured expectations

=item * reusable patterns

=item * a clean separation between setup and test logic

=back

=head1 PLAN STRUCTURE

A DeepMock plan is a hashref with the following keys:

=head2 C<mocks>

An arrayref of mock specifications. Each entry is a hashref:

    {
        target => 'Package::method',   # required
        type   => 'mock' | 'spy' | 'inject',
        with   => sub { ... },         # for mock/inject
        tag    => 'identifier',        # for spies or scoped mocks
        scoped => 1,                   # optional
    }

=head3 Types

=over 4

=item C<mock>

Replaces the target method with the provided coderef.

=item C<spy>

Wraps the method and records all calls. Must have a C<tag>.

=item C<inject>

Injects a value or behavior into the target (delegates to C<Test::Mockingbird::inject>).

=back

=head2 C<expectations>

An arrayref of expectation specifications. Each entry is a hashref:

    {
        tag   => 'double_spy',   # required
        calls => 2,              # optional
        args_like => [           # optional
            [ qr/foo/, qr/bar/ ],
        ],
    }

=head3 Expectation fields

=over 4

=item C<tag>

Identifies which spy this expectation applies to.

=item C<calls>

Expected number of calls.

=item C<args_eq>

Arrayref of arrayrefs. Each inner array lists exact argument values expected
for a specific call. Values are compared with C<Test::More::is>.

=item C<args_deeply>

Arrayref of arrayrefs. Each inner array lists deep structures to compare
against the arguments for a specific call. Uses C<Test::Deep::cmp_deeply>.

=item C<args_like>

Arrayref of arrayrefs of regexes. Each inner array describes expected
arguments for a specific call.

=item C<never>

Asserts that the spy was never called.
Mutually exclusive with C<calls>.

=back

=head2 C<globals>

Optional hashref controlling global behavior:

    globals => {
        restore_on_scope_exit => 1,   # default
    }

=head2 C<time>

Optional hashref describing a time-travel plan to apply while the
C<deep_mock> block is running. This integrates with
L<Test::Mockingbird::TimeTravel> and allows declarative control of frozen
time, time jumps, and temporal overrides.

If provided, the time plan is applied:

=over 4

=item 1. before any mocks are installed

=item 2. before the test code block is executed

=item 3. automatically restored after the block completes

=back

A time plan may include any of the following keys:

    time => {
        freeze  => '2025-01-01T00:00:00Z',
        travel  => '2025-01-02T12:00:00Z',
        advance => [ 2 => 'minutes' ],
        rewind  => [ 1 => 'hour'    ],
    }

=head3 C<freeze>

Freezes time at the given timestamp. Accepts any format supported by
C<Test::Mockingbird::TimeTravel>, including:

=over 4

=item * C<YYYY-MM-DD>

=item * C<YYYY-MM-DD HH:MM:SS>

=item * C<YYYY-MM-DDTHH:MM:SSZ>

=item * raw epoch seconds

=back

=head3 C<travel>

Moves the frozen clock to a new timestamp without unfreezing time.

=head3 C<advance>

Advances the frozen clock by a duration. Must be an arrayref:

    advance => [ $amount => $unit ]

Units may be C<seconds>, C<minutes>, C<hours>, or C<days>.

=head3 C<rewind>

Rewinds the frozen clock by a duration. Same format as C<advance>.

=head3 Example

    deep_mock(
        {
            time => {
                freeze  => '2025-01-01T00:00:00Z',
                advance => [ 2 => 'minutes' ],
            },
            mocks => [
                {
                    target => 'MyApp::stamp',
                    type   => 'mock',
                    with   => sub { now() },   # observes frozen time
                },
            ],
        },
        sub {
            is MyApp::stamp(),
               Test::Mockingbird::TimeTravel::_parse_datetime(
                   '2025-01-01T00:02:00Z'
               ),
               'mock sees advanced frozen time';
        }
    );

=head3 Restoration

All time-travel state is automatically restored after the C<deep_mock>
block completes, regardless of whether the block returns normally or dies.
This mirrors the automatic restoration of mocks.

=head1 COOKBOOK

=head2 Mocking a method

    mocks => [
        {
            target => 'MyApp::greet',
            type   => 'mock',
            with   => sub { "hi" },
        },
    ]

=head2 Spying on a method

    mocks => [
        {
            target => 'MyApp::double',
            type   => 'spy',
            tag    => 'dbl',
        },
    ]

=head2 Injecting a dependency

    mocks => [
        {
            target => 'MyApp::Config::get',
            type   => 'inject',
            with   => { debug => 1 },
        },
    ]

=head2 Expecting a call count

    expectations => [
        {
            tag   => 'dbl',
            calls => 3,
        },
    ]

=head2 Expecting argument patterns

    expectations => [
        {
            tag      => 'dbl',
            args_like => [
                [ qr/^\d+$/ ],     # first call
                [ qr/^\d+$/ ],     # second call
            ],
        },
    ]

=head2 Combining mocking with time travel

DeepMock can apply a time-travel plan (via
L<Test::Mockingbird::TimeTravel>) before installing mocks. This allows
tests to observe deterministic timestamps inside mocked methods or
spies.

    {
        package MyApp;
        sub stamp { time }   # original behaviour (non-deterministic)
        sub logit { $_[1] }
    }

    deep_mock(
        {
            time => {
                freeze  => '2025-01-01T00:00:00Z',
                advance => [ 2 => 'minutes' ],
            },
            mocks => [
                {
                    target => 'MyApp::stamp',
                    type   => 'mock',
                    with   => sub { now() },   # observe frozen time
                },
                {
                    target => 'MyApp::logit',
                    type   => 'spy',
                    tag    => 'log_spy',
                },
            ],
            expectations => [
                {
                    tag   => 'log_spy',
                    calls => 1,
                    args_like => [
                        [ qr/^event:/ ],
                    ],
                },
            ],
        },
        sub {
            my $t = MyApp::stamp();     # returns frozen + advanced time
            MyApp::logit("event:$t");   # spy records call + args
        }
    );

In this example:

=over 4

=item *

Time is frozen at C<2025-01-01T00:00:00Z> and advanced by two minutes
before any mocks are installed.

=item *

C<MyApp::stamp> is mocked to return C<now()>, giving a deterministic
timestamp inside the test.

=item *

C<MyApp::logit> is spied on, and its arguments are validated against
regex patterns.

=item *

After the block completes, both the mocking layer and the time-travel
layer are automatically restored.

=back


=head2 Full example

    deep_mock(
        {
            mocks => [
                { target => 'A::foo', type => 'mock', with => sub { 1 } },
                { target => 'A::bar', type => 'spy',  tag => 'bar' },
            ],
            expectations => [
                { tag => 'bar', calls => 2 },
            ],
        },
        sub {
            A::foo();
            A::bar(10);
            A::bar(20);
        }
    );

=head1 TROUBLESHOOTING

=head2 "Not enough arguments for deep_mock"

You are using the BLOCK prototype form:

    deep_mock {
        ...
    }, sub { ... };

This only works if C<deep_mock> has a C<(&$)> prototype AND the first
argument is a real block, not a hashref.

DeepMock uses C<($$)> to avoid Perl's block-vs-hashref ambiguity.

Use parentheses instead:

    deep_mock(
        { ... },
        sub { ... }
    );

=head2 "Type of arg 1 must be block or sub {}"

You are still using the BLOCK prototype form. Switch to parentheses.

=head2 "Use of uninitialized value in multiplication"

Your spied method is being called with no arguments during spy installation.
Make your method robust:

    sub double { ($_[1] // 0) * 2 }

=head2 My mocks aren't restored

Ensure you didn't disable automatic restore:

    globals => { restore_on_scope_exit => 0 }

=head2 Nested deep_mock scopes are not supported

DeepMock installs mocks using L<Test::Mockingbird>, which provides only
global restore semantics via C<restore_all>. Because Test::Mockingbird
does not expose a per-method restore API, DeepMock cannot safely restore
only the mocks installed in an inner scope.

As a result, nested calls like:

    deep_mock { ... } sub {
        deep_mock { ... } sub {
            ...
        };
    };

will cause the inner restore to remove the outer mocks as well.

DeepMock therefore does not support nested mocking scopes.

=head2 deep_mock

Run a block of code with a set of mocks and expectations applied.

=head3 Purpose

Provides a declarative wrapper around Test::Mockingbird that installs mocks,
runs a code block, and then validates expectations such as call counts and
argument patterns.

=head3 Arguments

=over 4

=item * C<$plan> - HashRef

A plan describing mocks and expectations. Keys:

=over 4

=item * C<mocks> - ArrayRef of mock specifications

Each specification includes:

- C<target> - "Package::method"
- C<type> - "mock" or "spy"
- C<with> - coderef for mock behavior (mock only)
- C<tag> - identifier for later expectations

=item * C<expectations> - ArrayRef of expectation specifications

Each specification includes:

- C<tag> - spy tag to validate
- C<calls> - expected call count
- C<args_like> - regex argument matching
- C<args_eq> - exact argument matching
- C<args_deeply> - deep structural matching
- C<never> - assert spy was not called

=back

=item * C<$code> - CodeRef

The block to execute while mocks are active.

=back

=head3 Returns

Nothing. Dies on expectation failure.

=head3 Side Effects

Temporarily installs mocks and spies into the target packages. All mocks are
removed after the code block completes.

=head3 Notes

This routine does not support nested deep_mock scopes. All mocks are global
until restored.

=head3 API

=head4 Input (Params::Validate::Strict)

    {
        mocks        => ArrayRef,
        expectations => ArrayRef,
    },
    CodeRef

=head4 Output (Returns::Set)

    returns: undef

=cut

sub deep_mock
{
	my ($plan, $code) = @_;

	croak 'deep_mock expects a HASHREF plan' unless ref $plan eq 'HASH';

	my %handles;

	# Apply time travel plan
	_apply_time_plan($plan->{time});

	# Install mocks for this scope and capture restore handles
	my @installed = _install_mocks($plan->{mocks} || [], \%handles);

	my ($wantarray, @ret, $ret, $err);
	$wantarray = wantarray;

	if ($wantarray) {
		@ret = eval { $code->() };
		$err = $@;
	} elsif (defined $wantarray) {
		$ret = eval { $code->() };
		$err = $@;
	} else {
		eval { $code->() };
		$err = $@;
	}

	_run_expectations($plan->{expectations} || [], \%handles);

	my $auto_restore = !exists $plan->{globals}{restore_on_scope_exit}
		|| $plan->{globals}{restore_on_scope_exit};

	Test::Mockingbird::restore_all() if $auto_restore;

	# Restore time travel state
	Test::Mockingbird::TimeTravel::restore_all();

	croak $err if $err;

	return $wantarray ? @ret : $ret;
}

# ----------------------------------------------------------------------
# NAME
#     _install_mocks
#
# PURPOSE
#     Install mocks and spies as described in the plan. Creates
#     Test::Mockingbird handles and stores them in the provided hash.
#
# ENTRY CRITERIA
#     - $mocks: ArrayRef of mock specifications
#     - $handles: HashRef for storing created mock and spy handles
#     - Each mock specification must include:
#         target => "Package::method"
#         type   => "mock" or "spy"
#         tag    => identifier for expectations
#         with   => coderef (required for type "mock")
#
# EXIT STATUS
#     - Returns a list of guard objects for later cleanup
#     - Croaks on invalid specifications
#
# SIDE EFFECTS
#     - Modifies symbol tables of target packages to install mocks/spies
#     - Populates $handles with created spy and mock handles
#
# NOTES
#     - Internal helper, not part of the public API
#     - Does not support nested mocking scopes
# ----------------------------------------------------------------------
sub _install_mocks {
	my ($mocks, $handles) = @_;

	my @installed;   # list of [$pkg, $method] for this scope

	for my $m (@$mocks) {
		my $target = $m->{target} or croak 'mock entry missing target';

		my ($pkg, $method) = _normalize_target($target);

		my $type = $m->{type} || 'mock';

		if ($type eq 'mock') {
			# --------------------------------------------------------------
			# MOCK
			# --------------------------------------------------------------
			croak "mock type requires 'with' coderef" unless defined $m->{with} && ref $m->{with} eq 'CODE';

			Test::Mockingbird::mock($pkg, $method, $m->{with});

			push @installed, [ $pkg, $method ];

			$handles->{ $m->{tag} }{guard} = 1 if $m->{tag};
		} elsif ($type eq 'spy') {
			# --------------------------------------------------------------
			# SPY
			# --------------------------------------------------------------
			my $spy = Test::Mockingbird::spy($pkg, $method);

			push @installed, [ $pkg, $method ];

			$handles->{ $m->{tag} }{spy} = $spy if $m->{tag};
		} elsif ($type eq 'inject') {
			# --------------------------------------------------------------
			# INJECT
			# --------------------------------------------------------------
			Test::Mockingbird::inject($pkg, $method, $m->{with});

			push @installed, [ $pkg, $method ];

			$handles->{ $m->{tag} }{inject} = 1 if $m->{tag};
		} else {
			croak "Unknown mock type '$type' for target '$target'";
		}
	}

	return @installed;
}

# ----------------------------------------------------------------------
# NAME
#     _run_expectations
#
# PURPOSE
#     Validate expectations against recorded spy calls. Supports call
#     counts, regex matching, exact matching, deep matching, and "never".
#
# ENTRY CRITERIA
#     - $expectations: ArrayRef of expectation specifications
#     - $handles: HashRef containing spy handles keyed by tag
#     - Each expectation may include:
#         tag          => spy tag to validate
#         calls        => expected call count
#         args_like    => regex argument matching
#         args_eq      => exact argument matching
#         args_deeply  => deep structural matching
#         never        => assert spy was not called
#
# EXIT STATUS
#     - Returns nothing
#     - Emits TAP output via Test::More and Test::Deep
#     - Croaks if a required spy handle is missing
#
# SIDE EFFECTS
#     - Produces test output
#
# NOTES
#     - Internal helper, not part of the public API
#     - Caller must ensure all tags refer to installed spies
# ----------------------------------------------------------------------

sub _run_expectations {
	my ($exps, $handles) = @_;

	for my $exp (@$exps) {
		my $tag = $exp->{tag}
		  or croak 'expectation missing tag';

		my $spy = $handles->{$tag}{spy}
		  or croak "no spy handle for tag '$tag'";

		my @calls = $spy->();   # each call: [ full_method, @args ]

		# --------------------------------------------------------------
		# CALL COUNT
		# --------------------------------------------------------------
		if (defined $exp->{calls}) {
			Test::More::is(
				scalar(@calls),
				$exp->{calls},
				"DeepMock: calls for $tag"
			);
		}

		# --------------------------------------------------------------
		# args_like  (regex matching)
		# --------------------------------------------------------------
		if (my $args_like = $exp->{args_like}) {
			for my $i (0 .. $#$args_like) {
				my $patterns = $args_like->[$i];
				my $call	 = $calls[$i] || [];
				my @args	 = @$call[1 .. $#$call];

				for my $j (0 .. $#$patterns) {
					my $re = $patterns->[$j];
					Test::More::like(
						$args[$j],
						ref $re ? $re : qr/$re/,
						"DeepMock: arg $j for call $i of $tag (args_like)"
					);
				}
			}
		}

		# --------------------------------------------------------------
		# args_eq  (exact string/number matching)
		# --------------------------------------------------------------
		if (my $args_eq = $exp->{args_eq}) {
			for my $i (0 .. $#$args_eq) {
				my $expected = $args_eq->[$i];
				my $call	 = $calls[$i] || [];
				my @args	 = @$call[1 .. $#$call];

				for my $j (0 .. $#$expected) {
					Test::More::is(
						$args[$j],
						$expected->[$j],
						"DeepMock: arg $j for call $i of $tag (args_eq)"
					);
				}
			}
		}

		# --------------------------------------------------------------
		# args_deeply  (structural deep comparison)
		# --------------------------------------------------------------
		if (my $args_deeply = $exp->{args_deeply}) {
			require Test::Deep;

			for my $i (0 .. $#$args_deeply) {
				my $expected = $args_deeply->[$i];
				my $call	 = $calls[$i] || [];
				my @args	 = @$call[1 .. $#$call];

				for my $j (0 .. $#$expected) {
					Test::Deep::cmp_deeply(
						$args[$j],
						$expected->[$j],
						"DeepMock: arg $j for call $i of $tag (args_deeply)"
					);
				}
			}
		}
		# --------------------------------------------------------------
		# never  (assert spy was never called)
		# --------------------------------------------------------------
		if ($exp->{never}) {
			Test::More::is(
				scalar(@calls),
				0,
				"DeepMock: $tag was never called"
			);
		}
	}
}

# ----------------------------------------------------------------------
# NAME
#     _normalize_target
#
# PURPOSE
#     Convert a target specification into a canonical (package, method)
#     pair. Accepts either "Package::method" or separate arguments.
#
# ENTRY CRITERIA
#     - $pkg_or_full: String, either "Package::method" or a package name
#     - $maybe_method: Optional string, method name if provided separately
#
# EXIT STATUS
#     - Returns a two element list: ($package, $method)
#     - Croaks if the target cannot be parsed
#
# SIDE EFFECTS
#     - None
#
# NOTES
#     - Internal helper, not part of the public API
#     - Caller must ensure the returned package and method exist or will
#       be created by mocking
# ----------------------------------------------------------------------

sub _normalize_target {
	# ENTRY: $arg1 may be 'Package::method' or a package name
	#		$arg2 may be a method name if provided separately
	my ($arg1, $arg2) = @_;

	# If only one arg and it looks like Package::method, split it
	if (defined $arg1 && !defined $arg2 && $arg1 =~ /^(.*)::([^:]+)$/) {
		return ($1, $2);
	}

	# Otherwise, return as-is (package, method)
	return ($arg1, $arg2);

	# EXIT: always returns ($pkg, $method)
}

sub _apply_time_plan {
	my $time = $_[0];
	return unless $time && ref $time eq 'HASH';

	if (exists $time->{freeze}) {
		Test::Mockingbird::TimeTravel::freeze_time($time->{freeze});
	}

	if (exists $time->{travel}) {
		Test::Mockingbird::TimeTravel::travel_to($time->{travel});
	}

	if (exists $time->{advance}) {
		my ($amount, $unit) = @{ $time->{advance} };
		Test::Mockingbird::TimeTravel::advance_time($amount, $unit);
	}

	if (exists $time->{rewind}) {
		my ($amount, $unit) = @{ $time->{rewind} };
		Test::Mockingbird::TimeTravel::rewind_time($amount, $unit);
	}
}

1;

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-test-mockingbird at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mockingbird>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Test::Mockingbird::DeepMock

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
