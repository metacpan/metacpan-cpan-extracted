package Test::Mockingbird;

use strict;
use warnings;
use 5.016003;

# ---------------------------------------------------------------------------
# Roadmap -- future work
# ---------------------------------------------------------------------------
#
# TODO: Strict mode (use Test::Mockingbird ':strict', or a per-call option):
#       croak when the target does not exist in the package or its parents.
#       Today a misspelled name (Pkg::fetch typed wrongly) creates a new sub and
#       the test passes against the real method (documented in LIMITATIONS).
#
# TODO: Argument-dispatching mocks, e.g.
#           mock_when 'Pkg::m' => [qr/foo/] => 'a', [1, 2] => 'b',
#                                 default   => sub { ... };
#       mock_sequence/mock_exception exist; dispatch on arguments does not.
#
# TODO: Assertion methods on spies: $spy->called_ok, ->called_with(...),
#       ->call_count.  Users currently count the list from $spy->() by hand;
#       DeepMock has these checks, but only inside its own DSL.  Needs spy()
#       to return a blessed callable object so existing $spy->() callers keep
#       working.
#
# TODO: Automatic restore_all() at the end of each subtest via a Test2 hook
#       (opt-in), so a forgotten unmock cannot leak into later subtests --
#       the failure mode that exposed GH#14.
#
# TODO: $ENV{TEST_MOCKINGBIRD_DEBUG} tracing flag that emits one line to
#       STDERR on each mock/unmock/restore_all operation (name, type, caller
#       location).  diagnose_mocks() covers post-hoc inspection; this would add
#       real-time per-operation tracing for troubleshooting complex stacking
#       scenarios.  Inspired by Function::Override's PERL_FUNCTION_OVERRIDE_DEBUG.
#
# TODO: Bridge TimeTravel and mock_core('time') (e.g. freeze_time(..., core
#       => 1)) so code compiled after the freeze sees the frozen clock through
#       the builtin, not only through TimeTravel::now().
#
# TODO: Per-object mocks: mock one instance without touching its class, by
#       blessing it into a generated singleton subclass that restore puts
#       back.  t/object.t currently exercises class-wide mocks only.
#
# TODO: AUTOLOAD-aware call-through: when _inherited_method() finds nothing,
#       fall back to the first AUTOLOAD in the MRO (setting $AUTOLOAD) instead
#       of croaking "Undefined subroutine" (documented in LIMITATIONS).
#
# TODO: Tests and documentation for mocking methods that carry Moo/Moose
#       method modifiers or come from roles.
#
# TODO: mock_core() call-through for builtins whose prototypes take
#       references (tie, pos, dbmopen, dbmclose): their $call_builtin croaks.
#       Could be done by generating a per-call-site delegator that
#       dereferences the argument.
#
# ---------------------------------------------------------------------------
# Technical debt
# ---------------------------------------------------------------------------
#
# TODO: Consolidate target parsing.  mock(), unmock(), before(), after() and
#       around() each repeat the shorthand/longhand regex instead of calling
#       _parse_target(), and three different discriminators are in use
#       (!defined $arg3, !defined $arg2, @_ == 2 in inject()).  The duplicated
#       conditions also show up as half-covered in Devel::Cover.
#
# TODO: Move %mocked, %mock_meta and @call_log into a registry object.  This
#       would allow independent mock sessions, fork-safe state, and a cleaner
#       extension point for DeepMock/Async than the 'local $TYPE' side channel.
#
# TODO: Let mock_scoped() guards own spies (and before/after/around layers)
#       so mixing them no longer needs restore_all().
#
# TODO: _is_core_overridable() only checks that prototype("CORE::$name")
#       does not die, so non-overridable keywords whose prototype is undef
#       (defined, exists, delete, my, ...) are accepted and mock_core()
#       installs an override Perl never consults.  Use an explicit list of
#       non-overridable keywords.
#
# TODO: Mutation pipeline (App::Test::Generator): stop re-emitting survivors
#       already killed by t/mutant_killers.t, stop generating new_ok() stubs
#       for this function-based module, and prune or archive old xt/ stubs
#       automatically.

use Carp       qw(croak carp);
use Exporter   'import';
use Scalar::Util ();
use mro ();

# Internal type-name constants -- eliminate magic strings.
# These constants are used wherever a layer type is recorded in %mock_meta.
use constant {
	_T_MOCK          => 'mock',
	_T_SPY           => 'spy',
	_T_INJECT        => 'inject',
	_T_MOCK_RETURN   => 'mock_return',
	_T_MOCK_EXCEPT   => 'mock_exception',
	_T_MOCK_SEQ      => 'mock_sequence',
	_T_MOCK_ONCE     => 'mock_once',
	_T_MOCK_SCOPED   => 'mock_scoped',
	_T_INTERCEPT_NEW => 'intercept_new',
	_T_BEFORE        => 'before',
	_T_AFTER         => 'after',
	_T_AROUND        => 'around',
	_T_MOCK_CORE     => 'mock_core',
};

our @EXPORT = qw(
	mock
	unmock
	mock_scoped
	mock_core
	before
	after
	around
	spy
	inject
	inject_all
	intercept_new
	restore
	restore_all
	mock_return
	mock_exception
	mock_sequence
	mock_once
	diagnose_mocks
	diagnose_mocks_pretty
	assert_call_order
	clear_call_log
);

# $TYPE is set via 'local' by sugar functions before delegating to mock()
# or inject() so that diagnose_mocks() records the correct layer type.
# External modules (e.g. Test::Mockingbird::Async) use the same mechanism.
our $TYPE;

# Internal mocking state -- module-level lexicals.
my %mocked;    # full_method => [ stack of saved coderefs; undef = no sub was declared ]
my %mock_meta; # full_method => [ { type => ..., installed_at => ... }, ... ]
my @call_log;  # ordered log of every spied call

=encoding utf-8

=head1 NAME

Test::Mockingbird - Advanced mocking library for Perl with support for
dependency injection, spies, call ordering, constructor interception, and
async Future mocking

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

  use Test::Mockingbird;

  # Mocking (shorthand form)
  mock 'My::Module::method' => sub { 'mocked' };

  # Mocking (longhand form)
  mock('My::Module', 'method', sub { 'mocked' });

  # Spying
  my $spy = spy 'My::Module::method';
  My::Module::method('arg1');
  my @calls = $spy->();   # ( ['My::Module::method', 'arg1'], ... )

  # Dependency injection
  inject 'My::Module::Dependency' => $mock_object;

  # Batch dependency injection
  inject_all('My::Module', {
      DB     => $mock_db,
      Logger => $mock_logger,
  });

  # Constructor interception
  intercept_new 'My::Service' => $stub_obj;
  intercept_new 'My::Service' => sub { My::Double->new(@_[1..$#_]) };

  # Unmock one layer
  unmock 'My::Module::method';

  # Restore everything
  restore_all();

  # Call ordering
  spy 'A::fetch';
  spy 'B::process';
  A::fetch();
  B::process();
  assert_call_order('A::fetch', 'B::process');
  clear_call_log();

=head1 DESCRIPTION

Test::Mockingbird provides mocking, spying, dependency injection,
call-order verification, and constructor interception for Perl test suites.

=head1 DIAGNOSTICS

L</diagnose_mocks> returns a structured hashref of all active mock layers;
L</diagnose_mocks_pretty> returns the same as a human-readable multi-line
string.

Each installed layer records:

  type          -- category (mock, spy, inject, mock_return, ...)
  installed_at  -- file and line number of the outermost user call site

=head1 LIMITATIONS

=over 4

=item A misspelled method name is mocked without complaint

C<mock 'My::Module::fecth' =E<gt> sub { ... }> installs a new sub called
C<fecth>; the real C<fetch> is left untouched and a test relying on the mock
may pass for the wrong reason.  Check with C<can> (or C<diagnose_mocks()>)
when a mock seems to have no effect.

=item Names with non-ASCII characters

Package and method names are used as given, so any name Perl accepts under
C<use utf8> (e.g. C<Café::prix>) can be mocked, spied on, injected and
restored.  C<mock_core()> only accepts ASCII builtin names, which covers
every Perl builtin.

=item Call-through to an inherited method does not consult C<AUTOLOAD>

When C<spy()>, C<before()>, C<after()>, C<around()> or C<async_spy()> wrap a
method the package does not declare itself, they call through to the first
implementation found in the package's parent classes (looked up at call
time, so a later mock of the parent is seen). If there is none they die with
C<"Undefined subroutine">; an C<AUTOLOAD> is not tried.

=item Prototype mismatch warning from C<spy()>

C<spy()> installs its wrapper directly without going through C<mock()>,
so C<Scalar::Util::set_prototype> is not applied. Wrapping a prototyped
function with C<spy()> still emits a C<Prototype mismatch> warning. Use
C<mock()> with a delegating wrapper if warning-free wrapping is required.

=item No nested deep_mock scopes

L<Test::Mockingbird::DeepMock> calls C<restore_all()> at scope exit, which
removes every active mock. Nested C<deep_mock> blocks cause the inner exit
to also tear down the outer mocks. Do not nest C<deep_mock> calls.

=item Thread safety

The internal state (C<%mocked>, C<%mock_meta>, C<@call_log>) is per-process
lexical state. Concurrent threads that install and restore mocks will race.
Do not use this module in threaded test harnesses without external locking.

=item Spy return value is a flat list

C<spy()> and C<async_spy()> return a coderef that yields a flat list of
call records. A future version may return an arrayref to reduce stack
pressure; the API is not yet changed to avoid breaking callers.

=item Private-function encapsulation

Functions prefixed with C<_> are private by convention but are not enforced
at runtime (C<Sub::Private> is not activated). White-box tests in C<t/unit.t>
call private functions directly. If C<Sub::Private> enforcement is added, a
testing-interface export mechanism will be required.

=back

=head1 METHODS

=head2 mock

Replace a method with a coderef.

    mock('My::Module', 'method', sub { 'mocked' });
    mock 'My::Module::method' => sub { 'mocked' };

Mocks stack in LIFO order. Each C<mock()> call saves the current CODE slot
(or notes that there is none, if the package does not declare the method)
and installs the replacement. C<unmock()> pops one layer; C<restore_all()>
drains all.

A method the package only inherits can be mocked in that package alone:

    mock 'My::Child::greet' => sub { 'mocked' };   # My::Parent unaffected
    unmock 'My::Child::greet';                      # inherits again

Removing the last layer empties the package's CODE slot, so method lookup
reaches the parent class again, exactly as before the mock.

If the original carries a Perl prototype, the same prototype is stamped onto
the replacement coderef before installation, suppressing C<Prototype mismatch>
warnings.

=head3 API SPECIFICATION

=head4 Input

    target      -- Str, 'Pkg::method' or ('Pkg', 'method')
    replacement -- CodeRef

=head4 Output

    returns: undef

=head3 MESSAGES

  "Package, method and replacement are required for mocking"
      -- package, method or replacement missing (undef, '' or false)
  "mock: replacement for 'Pkg::method' must be a coderef"
      -- replacement is a string or a non-CODE reference

=cut

sub mock {
	my ($arg1, $arg2, $arg3) = @_;

	my ($package, $method, $replacement);

	# Shorthand: 'Pkg::method' => $code (arg3 absent)
	if (defined $arg1 && !defined $arg3 && $arg1 =~ /^(.*)::([^:]+)$/) {
		($package, $method, $replacement) = ($1, $2, $arg2);
	} else {
		($package, $method, $replacement) = ($arg1, $arg2, $arg3);
	}

	croak 'Package, method and replacement are required for mocking'
		unless _is_name($package) && _is_name($method) && $replacement;

	# Anything but a coderef is silently installed wrongly by the glob
	# assignment below: a string aliases the whole typeglob to another
	# symbol and a reference fills the wrong slot, leaving the method real.
	croak "mock: replacement for '${package}::${method}' must be a coderef"
		unless ref($replacement) eq 'CODE';

	my $full_method = "${package}::${method}";

	# Capture the current CODE slot.  When no sub of that name has been
	# declared in the package, undef is saved instead: on restore the CODE
	# slot is emptied (see _restore_slot) so that inherited methods resolve
	# through @ISA again.  Restoration always writes back to the SAME GV that
	# compiled direct calls hold, never deleting it.
	my ($orig_existed, $original) = _capture_slot($full_method);
	push @{ $mocked{$full_method} }, $original;

	# Stamp the prototype onto the replacement to avoid Perl warning about
	# "Prototype mismatch" when the original had a prototype.
	my $orig_proto = defined $original ? prototype($original) : undef;
	if (defined $orig_proto) {
		&Scalar::Util::set_prototype($replacement, $orig_proto);
	}

	{
		# 'redefine' suppresses "Subroutine ... redefined".
		# 'prototype' suppresses "Prototype mismatch" -- that warning lives in
		# a separate category and is not covered by 'redefine'.  set_prototype()
		# above should already make the prototypes equal, but on some Perl builds
		# the GV-level check still fires before the CV slot is fully updated, so
		# we suppress the warning here.
		no warnings 'redefine', 'prototype';
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		*{$full_method} = $replacement;
	}

	push @{ $mock_meta{$full_method} }, {
		type             => $TYPE // _T_MOCK,
		installed_at     => _caller_info(),
		original_existed => $orig_existed,
	};

	return;
}

=head2 unmock

Restore the previous implementation of a mocked method (one layer).

    unmock('My::Module', 'method');
    unmock 'My::Module::method';

If the package did not declare the method before it was mocked, removing
the last layer empties its CODE slot: an inherited method is found through
C<@ISA> again, and a method defined nowhere is once more undefined (a direct
call dies with C<"Undefined subroutine"> and C<< ->can() >> returns false).
The typeglob itself and its other slots (e.g. a package variable of the same
name) are kept, so previously compiled direct calls still see later mocks.

=head3 API SPECIFICATION

=head4 Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')

=head4 Output

    returns: undef

=head3 MESSAGES

  "Package and method are required for unmocking" -- target missing

=cut

sub unmock {
	my ($arg1, $arg2) = @_;

	my ($package, $method);
	if (defined $arg1 && !defined $arg2 && $arg1 =~ /^(.*)::([^:]+)$/) {
		($package, $method) = ($1, $2);
	} else {
		($package, $method) = ($arg1, $arg2);
	}

	croak 'Package and method are required for unmocking'
		unless _is_name($package) && _is_name($method);

	my $full_method = "${package}::${method}";

	# Nothing to do if this method was never mocked
	return unless exists $mocked{$full_method} && @{ $mocked{$full_method} };

	_restore_slot($full_method, pop @{ $mocked{$full_method} });

	# Pop exactly one meta entry to mirror the mock stack.
	# Earlier code deleted the entire key; that wiped meta for all layers
	# still on the stack after a partial unmock.
	pop @{ $mock_meta{$full_method} };

	# Clean up empty tracking structures
	unless (@{ $mocked{$full_method} }) {
		delete $mocked{$full_method};
		delete $mock_meta{$full_method};
	}

	return;
}

=head2 before

Run a hook before a method, then call the original and return its value.

    before 'My::Module::method' => sub { my @args = @_; ... };
    before('My::Module', 'method', sub { ... });

The hook receives the same C<@_> that the original would have received. Its
return value is discarded. The original is always called and its return value
is passed to the caller unchanged. Context (list / scalar / void) is
preserved.

Uses the same LIFO mock stack as C<mock()>: C<unmock()> peels one layer,
C<restore_all()> drains all. C<diagnose_mocks()> records the layer type as
C<'before'>.

=head3 API SPECIFICATION

=head4 Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')
    hook   -- CodeRef; receives (@original_args), return value discarded

=head4 Output

    returns: undef

=head3 MESSAGES

  "Package, method and hook are required for before()" -- target or hook missing or non-CODE

=cut

sub before {
	my ($arg1, $arg2, $arg3) = @_;

	my ($package, $method, $hook);
	if (defined $arg1 && !defined $arg3 && $arg1 =~ /^(.*)::([^:]+)$/) {
		($package, $method, $hook) = ($1, $2, $arg2);
	} else {
		($package, $method, $hook) = ($arg1, $arg2, $arg3);
	}

	croak 'Package, method and hook are required for before()'
		unless _is_name($package) && _is_name($method) && ref($hook) eq 'CODE';

	my $full_method = "${package}::${method}";
	my $orig = _call_through($package, $method);

	local $TYPE = _T_BEFORE;
	mock($package, $method, sub {
		my @args = @_;
		$hook->(@args);
		if (wantarray) {
			return $orig->(@args);
		} elsif (defined wantarray) {
			return scalar $orig->(@args);
		} else {
			$orig->(@args);
			return;
		}
	});

	return;
}

=head2 after

Run a hook after a method and return the original's value.

    after 'My::Module::method' => sub { my @args = @_; ... };
    after('My::Module', 'method', sub { ... });

The original is called first. Its return value is captured, then the hook is
called with the same C<@_> that the original received. The hook's return
value is discarded and the original's return value is passed to the caller
unchanged. Context (list / scalar / void) is preserved.

If the original throws, the exception propagates immediately and the hook is
B<not> called. Use C<around()> if you need to run code unconditionally after
the original.

Uses the same LIFO mock stack as C<mock()>: C<unmock()> peels one layer,
C<restore_all()> drains all. C<diagnose_mocks()> records the layer type as
C<'after'>.

=head3 API SPECIFICATION

=head4 Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')
    hook   -- CodeRef; receives (@original_args), return value discarded

=head4 Output

    returns: undef

=head3 MESSAGES

  "Package, method and hook are required for after()" -- target or hook missing or non-CODE

=cut

sub after {
	my ($arg1, $arg2, $arg3) = @_;

	my ($package, $method, $hook);
	if (defined $arg1 && !defined $arg3 && $arg1 =~ /^(.*)::([^:]+)$/) {
		($package, $method, $hook) = ($1, $2, $arg2);
	} else {
		($package, $method, $hook) = ($arg1, $arg2, $arg3);
	}

	croak 'Package, method and hook are required for after()'
		unless _is_name($package) && _is_name($method) && ref($hook) eq 'CODE';

	my $full_method = "${package}::${method}";
	my $orig = _call_through($package, $method);

	local $TYPE = _T_AFTER;
	mock($package, $method, sub {
		my @args = @_;
		if (wantarray) {
			my @ret = $orig->(@args);
			$hook->(@args);
			return @ret;
		} elsif (defined wantarray) {
			my $ret = $orig->(@args);
			$hook->(@args);
			return $ret;
		} else {
			$orig->(@args);
			$hook->(@args);
			return;
		}
	});

	return;
}

=head2 around

Replace a method with a hook that receives the original coderef as its first
argument.

    around 'My::Module::method' => sub {
        my ($orig, @args) = @_;
        my $result = $orig->(@args);   # call original
        return $result * 2;            # modify return value
    };

    around('My::Module', 'method', sub {
        my ($orig, @args) = @_;
        return $orig->(@args);
    });

The hook receives C<($orig_coderef, @original_args)>. It may call C<$orig>
zero or more times with any arguments. Its return value becomes the return
value of the method. The hook is responsible for context handling when that
matters.

C<around()> is the preferred alternative to C<mock()> when you need to call
through to the original: it captures the original and passes it as the first
argument, avoiding the boilerplate of a separate C<\&{...}> capture.

Uses the same LIFO mock stack as C<mock()>: C<unmock()> peels one layer,
C<restore_all()> drains all. C<diagnose_mocks()> records the layer type as
C<'around'>.

=head3 API SPECIFICATION

=head4 Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')
    hook   -- CodeRef; receives ($orig_coderef, @original_args)

=head4 Output

    returns: undef

=head3 MESSAGES

  "Package, method and hook are required for around()" -- target or hook missing or non-CODE

=cut

sub around {
	my ($arg1, $arg2, $arg3) = @_;

	my ($package, $method, $hook);
	if (defined $arg1 && !defined $arg3 && $arg1 =~ /^(.*)::([^:]+)$/) {
		($package, $method, $hook) = ($1, $2, $arg2);
	} else {
		($package, $method, $hook) = ($arg1, $arg2, $arg3);
	}

	croak 'Package, method and hook are required for around()'
		unless _is_name($package) && _is_name($method) && ref($hook) eq 'CODE';

	my $full_method = "${package}::${method}";
	my $orig = _call_through($package, $method);

	local $TYPE = _T_AROUND;
	mock($package, $method, sub { $hook->($orig, @_) });

	return;
}

=head2 mock_scoped

Create a scoped mock that restores automatically when the guard goes out of scope.

=head3 Single-method forms

    my $g = mock_scoped 'My::Module::method' => sub { 'mocked' };
    my $g = mock_scoped('My::Module', 'method', sub { ... });

=head3 Multi-method forms

    my $g = mock_scoped('My::Module',
        fetch  => sub { 'mocked_fetch'  },
        save   => sub { 'mocked_save'   },
    );

    my $g = mock_scoped(
        'My::Module::fetch'  => sub { 'mocked_fetch'  },
        'Other::Module::save' => sub { 'mocked_save'  },
    );

All mocked methods are restored when C<$g> goes out of scope.

=head3 API SPECIFICATION

=head4 Input

    args -- four recognised forms (see above)

=head4 Output

    returns: Test::Mockingbird::Guard

=head3 MESSAGES

  "mock_scoped: unrecognised argument form" -- none of the four forms matched
  "mock_scoped: expected coderef for '$target'" -- non-CODE value provided

=cut

sub mock_scoped {
	my @args = @_;

	my @pairs;

	if (@args == 2 && ref($args[1]) eq 'CODE') {
		my ($pkg, $meth) = _parse_target($args[0]);
		push @pairs, [ $pkg, $meth, $args[1] ];

	} elsif (@args == 3 && !ref($args[1]) && ref($args[2]) eq 'CODE') {
		push @pairs, [ $args[0], $args[1], $args[2] ];

	} elsif (@args >= 4 && (@args % 2) == 0 && ref($args[1]) eq 'CODE') {
		my @a = @args;
		while (@a) {
			my ($target, $code) = splice @a, 0, 2;
			croak "mock_scoped: expected coderef for '$target'"
				unless ref($code) eq 'CODE';
			my ($pkg, $meth) = _parse_target($target);
			push @pairs, [ $pkg, $meth, $code ];
		}

	} elsif (@args >= 5 && (@args % 2) == 1 && ref($args[2]) eq 'CODE') {
		my @a   = @args;
		my $pkg = shift @a;
		while (@a) {
			my ($meth, $code) = splice @a, 0, 2;
			croak "mock_scoped: expected coderef for method '$meth'"
				unless ref($code) eq 'CODE';
			push @pairs, [ $pkg, $meth, $code ];
		}

	} else {
		croak 'mock_scoped: unrecognised argument form';
	}

	my @full_methods;
	{
		local $TYPE = _T_MOCK_SCOPED;
		for my $pair (@pairs) {
			my ($pkg, $meth, $code) = @{$pair};
			mock($pkg, $meth, $code);
			push @full_methods, "${pkg}::${meth}";
		}
	}

	return Test::Mockingbird::Guard->new(@full_methods);
}

=head2 spy

Wrap a method so that every call is recorded. The original method is still
called and its return value is passed back to the caller.

    my $spy = spy 'My::Module::method';
    My::Module::method('arg');
    my @calls = $spy->();   # ( ['My::Module::method', 'arg'], ... )
    restore_all();

Returns a coderef that, when invoked, returns the list of captured call
records. Each record is an arrayref C<[ $full_method, @args ]>.

=head3 API SPECIFICATION

=head4 Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')

=head4 Output

    returns: CodeRef   # yields list of call records on invocation

=head3 MESSAGES

  "Package and method are required for spying" -- target missing or incomplete

=cut

sub spy {
	my ($package, $method) = _parse_target(@_);

	croak 'Package and method are required for spying'
		unless _is_name($package) && _is_name($method);

	my $full_method = "${package}::${method}";

	# Save the current CODE slot for restoration (see mock()), and resolve
	# what the wrapper calls through to -- which, for a method the package
	# only inherits, is the parent's implementation.
	my ($orig_existed, $saved) = _capture_slot($full_method);
	push @{ $mocked{$full_method} }, $saved;
	my $orig = _call_through($package, $method);

	my @calls;

	my $wrapper = sub {
		push @calls,    [ $full_method, @_ ];
		push @call_log, $full_method;
		# A recursive method re-enters this wrapper and is recorded once per
		# call, outermost first (t/unit.t: "spy(): recursive calls").
		return $orig->(@_);
	};

	# Preserve the original's prototype to suppress "Prototype mismatch"
	# warnings and ensure '_'-prototype functions (stat, lstat, etc.) bind
	# $_ correctly at the call site when wrapped.
	my $orig_proto = prototype($orig);
	if (defined $orig_proto) {
		&Scalar::Util::set_prototype($wrapper, $orig_proto);
	}

	{
		no warnings 'redefine', 'prototype';
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		*{$full_method} = $wrapper;
	}

	push @{ $mock_meta{$full_method} }, {
		type             => _T_SPY,
		installed_at     => _caller_info(),
		original_existed => $orig_existed,
	};

	return sub { @calls };
}

=head2 inject

Inject a mock dependency into a package.

    inject('My::Module', 'Dependency', $mock_object);
    inject 'My::Module::Dependency' => $mock_object;

Injecting C<undef> is valid; use argument count (not definedness of the
third argument) to distinguish shorthand from longhand.

=head3 API SPECIFICATION

=head4 Input

    package    -- Str
    dependency -- Str
    value      -- Any (including undef)

=head4 Output

    returns: undef

=head3 MESSAGES

  "Package and dependency are required for injection" -- missing name, or a
      two-argument call whose target has no '::'

=cut

sub inject {
	my ($package, $dependency, $mock_object);

	# Discriminate shorthand (2 args) from longhand (3 args) by argument
	# count rather than definedness of the third arg so that inject(Pkg,
	# Dep, undef) -- injecting undef -- is correctly handled.
	# Two arguments are always the shorthand form; a target without '::'
	# leaves $package undef and croaks below, rather than being read as
	# longhand and silently injecting undef under the value's name.
	if (@_ == 2) {
		($package, $dependency) = $_[0] =~ /^(.*)::([^:]+)$/ if defined $_[0];
		$mock_object = $_[1];
	} else {
		($package, $dependency, $mock_object) = @_;
	}

	croak 'Package and dependency are required for injection'
		unless _is_name($package) && _is_name($dependency);

	my $full = "${package}::${dependency}";

	my ($orig_existed, $orig) = _capture_slot($full);
	push @{ $mocked{$full} }, $orig;

	my $wrapper = sub { $mock_object };

	{
		no warnings 'redefine';
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		*{$full} = $wrapper;
	}

	# inject() respects $TYPE so that inject_all() or any future wrapper
	# can label the layer differently (though 'inject' is the sensible default).
	push @{ $mock_meta{$full} }, {
		type             => $TYPE // _T_INJECT,
		installed_at     => _caller_info(),
		original_existed => $orig_existed,
	};

	return;
}

=head2 inject_all

Inject multiple dependencies into a package in one call.

    inject_all('My::Service', {
        DB     => $mock_db,
        Logger => $mock_logger,
    });

An empty hashref is a no-op. Each pair is equivalent to a separate
C<inject()> call and participates in the same mock stack.

=head3 API SPECIFICATION

=head4 Input

    package      -- Str
    dependencies -- HashRef

=head4 Output

    returns: undef

=head3 MESSAGES

  "inject_all requires a package name"            -- undef or empty package
  "inject_all requires a hashref of dependencies" -- second arg not a HashRef

=cut

sub inject_all {
	my ($package, $deps) = @_;

	croak 'inject_all requires a package name'
		unless defined $package && length $package;

	croak 'inject_all requires a hashref of dependencies'
		unless ref $deps eq 'HASH';

	inject($package, $_, $deps->{$_}) for keys %$deps;

	return;
}

=head2 intercept_new

Intercept the C<new> constructor of a class.

    intercept_new 'My::Service' => $stub_obj;
    intercept_new 'My::Service' => sub { My::Double->new(@_[1..$#_]) };

When given a plain value (including undef), every call to
C<< My::Service->new >> returns that value. When given a coderef, every
call invokes the coderef with the original arguments (including the class
name as the first argument) and returns its result.

This is a thin wrapper around C<mock()>; C<restore_all()>, C<unmock()>,
and C<diagnose_mocks()> all work identically.

=head3 API SPECIFICATION

=head4 Input

    class   -- Str (non-empty)
    factory -- Any; CodeRef invoked per call, or scalar returned verbatim

=head4 Output

    returns: undef

=head3 MESSAGES

  "intercept_new requires a class name"                    -- undef/empty class
  "intercept_new requires a replacement object or coderef" -- factory missing

=cut

sub intercept_new {
	my ($class, $factory) = @_;

	croak 'intercept_new requires a class name'
		unless defined $class && length $class;
	croak 'intercept_new requires a replacement object or coderef'
		if @_ < 2;

	my $replacement = ref($factory) eq 'CODE'
		? $factory
		: sub { $factory };

	local $TYPE = _T_INTERCEPT_NEW;
	mock("${class}::new", $replacement);

	return;
}

=head2 mock_core

Override a CORE Perl builtin globally via C<CORE::GLOBAL>.

    # Intercept 'warn' for code compiled after this point
    mock_core 'warn' => sub {
        my ($call_warn, @msgs) = @_;
        push @captured, @msgs;   # capture without emitting
    };

    # Call through to the real builtin via $call_builtin
    mock_core 'stat' => sub {
        my ($call_stat, $file) = @_;
        return $call_stat->($file);   # delegates to CORE::stat
    };

    unmock 'CORE::GLOBAL::warn';   # peel one layer
    restore_all();                 # drain all layers

The replacement receives C<($call_builtin, @original_args)>, mirroring the
C<around()> API.  C<$call_builtin> is a coderef that calls C<CORE::$name>
directly, bypassing any other C<CORE::GLOBAL> override.  Builtins with a
fixed argument list, such as C<time>, C<index> and C<substr>, get their
arguments passed by position.  A few builtins take arguments that no coderef
can pass on (C<tie>, C<pos>, C<dbmopen>, C<dbmclose>): they can still be
mocked, but calling C<$call_builtin> croaks.

The override is installed in C<CORE::GLOBAL::$name>, which is Perl's
documented mechanism for intercepting named builtins.  It affects all
packages globally.

B<Compile-time semantics:> C<CORE::GLOBAL> overrides are visible to code
compiled I<after> the override is installed.  To intercept calls in a module
under test, install the mock I<before> loading that module (a C<BEGIN> block
works).  Already-compiled call sites (including direct calls in the current
test file) are not affected at runtime.  Use string C<eval> when you need
code compiled in the same test run to see the override.

The wrapper carries the same prototype as C<CORE::$name> so that call-site
argument binding (such as the C<_> prototype that reads C<$_> when no
argument is given) is preserved.

Participates in the same LIFO mock stack as C<mock()>.  C<unmock>,
C<restore()>, and C<restore_all()> accept C<'CORE::GLOBAL::$name'> as the
target.  C<diagnose_mocks()> records the layer type as C<'mock_core'>.

B<Limitation:> builtins whose prototype begins with C<&> (C<sort>, C<map>,
C<grep>) require a literal code block at the call site and cannot be wrapped.

=head3 API SPECIFICATION

=head4 Input

    name        -- Str, CORE builtin name (no 'CORE::' prefix required)
    replacement -- CodeRef; receives ($call_builtin, @original_args)

=head4 Output

    returns: undef

=head3 MESSAGES

  "mock_core requires a builtin name and a replacement coderef" -- wrong arg types
  "mock_core: '$name' is not a valid identifier"               -- name has punctuation
  "mock_core: '$name' is not an overridable Perl builtin"      -- unknown builtin
  "mock_core: cannot call through to CORE::$name: ..."         -- $call_builtin
      called for a builtin whose arguments cannot be delegated

=cut

sub mock_core {
	my ($name, $replacement) = @_;

	croak 'mock_core requires a builtin name and a replacement coderef'
		unless defined $name && ref($replacement) eq 'CODE';

	$name =~ s/^CORE:://;    # tolerate an optional 'CORE::' prefix

	croak "mock_core: '$name' is not a valid identifier"
		unless $name =~ /^\w+$/;
	croak "mock_core: '$name' is not an overridable Perl builtin"
		unless _is_core_overridable($name);

	my $core_proto = eval { my $p = prototype("CORE::$name"); $p };
	my $call_core  = _core_delegator($name, $core_proto);

	# Wrap in an around-style closure and stamp the CORE prototype onto it
	# so call-site argument binding (e.g. '_' reads $_ when arg omitted) works.
	# List-op builtins (warn, die, print ...) have no traditional prototype
	# string (prototype("CORE::warn") returns undef), but Perl's CORE::GLOBAL
	# mechanism expects the override to carry '@'.  Use '@' as the fallback so
	# the wrapper's prototype matches and suppresses "Prototype mismatch" at
	# eval-compile time.
	my $wrapper        = sub { $replacement->($call_core, @_) };
	my $effective_proto = defined($core_proto) ? $core_proto : '@';
	&Scalar::Util::set_prototype($wrapper, $effective_proto);

	# Install in CORE::GLOBAL -- Perl's documented mechanism for global
	# builtin overrides.  Track under the full name so unmock/restore_all work.
	my $full = "CORE::GLOBAL::$name";

	my ($orig, $orig_existed);
	{
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		$orig_existed = defined(&{$full}) ? 1 : 0;
		# When no prior override existed, push undef rather than \&{$full}.
		# \&{$full} auto-vivifies the stash entry and returns an undef-stub CV.
		# Reinstating that stub on restore would leave a CORE::GLOBAL entry
		# whose non-NULL CV pointer makes Perl treat it as an active override,
		# preventing fallback to the real builtin.  _drain_and_restore detects
		# undef and deletes the stash entry instead.
		$orig = $orig_existed ? \&{$full} : undef;
	}
	push @{ $mocked{$full} }, $orig;

	{
		no warnings 'redefine', 'prototype';
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		*{$full} = $wrapper;
	}

	push @{ $mock_meta{$full} }, {
		type             => $TYPE // _T_MOCK_CORE,
		installed_at     => _caller_info(),
		original_existed => $orig_existed,
	};

	return;
}

=head2 restore_all

Restore all mocked methods and injected dependencies.

    restore_all();            # restore everything
    restore_all 'My::Module'; # restore only My::Module's mocks

When called with a package name, the mocks in that package B<and its
sub-packages> are restored: C<restore_all('My::Module')> also restores
C<My::Module::Helper::fn>, but not C<My::ModuleX::fn>. The call-order log is
pruned the same way.

=head3 API SPECIFICATION

=head4 Input

    package -- Str, optional

=head4 Output

    returns: undef

=cut

sub restore_all {
	my $arg = $_[0];

	if (defined $arg) {
		my $package = $arg;

		for my $full_method (keys %mocked) {
			next unless $full_method =~ /^\Q$package\E::/;
			_drain_and_restore($full_method);
			# _drain_and_restore explicitly skips hash cleanup; do it here
			# to match the behaviour of the global form (%mocked = (); etc.).
			delete $mocked{$full_method};
			delete $mock_meta{$full_method};
		}

		# Remove call_log entries for the restored package
		@call_log = grep { $_ !~ /^\Q$package\E::/ } @call_log;

		return;
	}

	# Global restore: revert every tracked method to its saved state
	_drain_and_restore($_) for keys %mocked;

	%mocked    = ();
	%mock_meta = ();
	@call_log  = ();

	return;
}

=head2 restore

Restore all mock layers for a single method target.

    restore 'My::Module::method';

If the method was never mocked this is a no-op.

=head3 API SPECIFICATION

=head4 Input

    target -- Str

=head4 Output

    returns: undef

=head3 MESSAGES

  "restore requires a target" -- undef target

=cut

sub restore {
	my $target = $_[0];

	croak 'restore requires a target' unless defined $target;

	my ($package, $method) = _parse_target($target);
	my $full_method = "${package}::${method}";

	return unless exists $mocked{$full_method};

	_drain_and_restore($full_method);
	delete $mocked{$full_method};
	delete $mock_meta{$full_method};

	return;
}

=head2 mock_return

Mock a method to always return a fixed value.

    mock_return 'My::Module::method' => 42;

=head3 API SPECIFICATION

=head4 Input

    target -- Str
    value  -- Any

=head4 Output

    returns: undef

=head3 MESSAGES

  "mock_return requires a target and a value" -- target undefined

=cut

sub mock_return {
	my ($target, $value) = @_;

	croak 'mock_return requires a target and a value' unless defined $target;

	local $TYPE = _T_MOCK_RETURN;
	mock $target => sub { $value };

	return;
}

=head2 mock_exception

Mock a method to always throw an exception.

    mock_exception 'My::Module::method' => 'something went wrong';

=head3 API SPECIFICATION

=head4 Input

    target  -- Str
    message -- Str

=head4 Output

    returns: undef

=head3 MESSAGES

  "mock_exception requires a target and an exception message" -- either missing

=cut

sub mock_exception {
	my ($target, $message) = @_;

	croak 'mock_exception requires a target and an exception message'
		unless defined $target && defined $message;

	local $TYPE = _T_MOCK_EXCEPT;
	mock $target => sub { croak $message };

	return;
}

=head2 mock_sequence

Mock a method to return a sequence of values over successive calls.
The last value repeats when the sequence is exhausted.

    mock_sequence 'My::Module::method' => (1, 2, 3);

=head3 API SPECIFICATION

=head4 Input

    target -- Str
    values -- Array (one or more)

=head4 Output

    returns: undef

=head3 MESSAGES

  "mock_sequence requires a target and at least one value" -- empty value list

=cut

sub mock_sequence {
	my ($target, @values) = @_;

	croak 'mock_sequence requires a target and at least one value'
		unless defined $target && @values;

	my @queue = @values;

	local $TYPE = _T_MOCK_SEQ;
	mock $target => sub {
		return $queue[0] if @queue == 1;
		return shift @queue;
	};

	return;
}

=head2 mock_once

Install a mock that fires exactly once. After the first call the previous
implementation is automatically restored.

    mock_once 'My::Module::method' => sub { 'temporary' };

=head3 API SPECIFICATION

=head4 Input

    target -- Str
    code   -- CodeRef

=head4 Output

    returns: undef

=head3 MESSAGES

  "mock_once requires a target and a coderef" -- missing or non-CODE factory

=head3 PSEUDOCODE

    parse target → (package, method)
    wrapper = sub {
        result = code(@_)
        unmock(package, method)   -- pop this very layer
        return result
    }
    install wrapper via mock() with TYPE='mock_once'

=cut

sub mock_once {
	my ($target, $code) = @_;

	croak 'mock_once requires a target and a coderef'
		unless defined $target && ref($code) eq 'CODE';

	my ($package, $method) = _parse_target($target);

	my $wrapper = sub {
		my @result = $code->(@_);
		Test::Mockingbird::unmock($package, $method);
		return wantarray ? @result : $result[0];
	};

	local $TYPE = _T_MOCK_ONCE;
	mock $target => $wrapper;

	return;
}

=head2 assert_call_order

Assert that the named methods were called in left-to-right order.

    assert_call_order('A::fetch', 'B::process', 'C::save');

Produces one TAP ok/not-ok line and returns a boolean. Intervening calls
to other methods are ignored.

=head3 API SPECIFICATION

=head4 Input

    methods -- Array of Str (two or more fully-qualified names)

=head4 Output

    returns: Bool

=head3 MESSAGES

  "assert_call_order requires at least two method names" -- fewer than two given

=cut

sub assert_call_order {
	my @expected = @_;

	croak 'assert_call_order requires at least two method names'
		unless @expected >= 2;

	my $pos = 0;
	for my $logged (@call_log) {
		if ($logged eq $expected[$pos]) {
			$pos++;
			last if $pos == @expected;
		}
	}

	my $ok = ($pos == @expected);

	require Test::More;
	if ($ok) {
		Test::More::pass("call order: " . join(' -> ', @expected));
	} else {
		Test::More::fail("call order: " . join(' -> ', @expected));
		Test::More::diag(
			"Expected '$expected[$pos]' next but it was not in the call log"
		);
	}

	return $ok;
}

=head2 clear_call_log

Clear the call-order log without restoring mocks or spies.

    clear_call_log();

C<restore_all()> also clears the log automatically.

=head3 API SPECIFICATION

=head4 Input

    none

=head4 Output

    returns: undef

=cut

sub clear_call_log {
	@call_log = ();
	return;
}

# _record_call -- Private helper
#
# Purpose:      Append a fully-qualified method name to the call-order log.
#               Used by Test::Mockingbird::Async to participate in
#               assert_call_order() without crossing the lexical boundary of
#               @call_log.
# Entry:        $_[0] -- Str, fully-qualified method name
# Exit:         undef
# Side effects: Appends to @call_log
sub _record_call {
	push @call_log, $_[0];
	return;
}

=head2 diagnose_mocks

Return a structured hashref of all currently active mock layers.

    my $diag = diagnose_mocks();
    # $diag->{'My::Pkg::method'} = {
    #   depth            => 1,
    #   layers           => [ { type => 'mock_return', installed_at => '...' } ],
    # }

=head3 API SPECIFICATION

=head4 Input

    none

=head4 Output

    returns: HashRef

=cut

sub diagnose_mocks {
	my %report;

	for my $full_method (sort keys %mocked) {
		my $layers = $mock_meta{$full_method} // [];
		$report{$full_method} = {
			depth            => scalar @{ $mocked{$full_method} },
			layers           => [ @$layers ],
			# original_existed reflects whether the method existed before the
			# FIRST mock layer was installed (stored in the bottom-most meta entry)
			original_existed => (@$layers && $layers->[0]{original_existed}) ? 1 : 0,
		};
	}

	return \%report;
}

=head2 diagnose_mocks_pretty

Return a human-readable multi-line string of all active mock layers.

=head3 API SPECIFICATION

=head4 Input

    none

=head4 Output

    returns: Str

=cut

sub diagnose_mocks_pretty {
	my $diag = diagnose_mocks();
	my @out;

	for my $full_method (sort keys %$diag) {
		my $entry = $diag->{$full_method};
		push @out, "$full_method:";
		push @out, "  depth: $entry->{depth}";
		push @out, "  original_existed: $entry->{original_existed}";
		for my $layer (@{ $entry->{layers} }) {
			push @out, sprintf "  - type: %-14s installed_at: %s",
				$layer->{type}, $layer->{installed_at};
		}
		push @out, '';
	}

	return join "\n", @out;
}

# _drain_and_restore -- Private helper
#
# Purpose:      Pop all layers from the mock stack for a single target and
#               restore the bottom-most saved coderef to the symbol table.
#               Does NOT clean up %mocked or %mock_meta -- callers must do
#               that themselves.
# Entry:        $_[0] -- Str, fully-qualified method name
# Exit:         undef
# Side effects: Modifies the symbol table for the target.
sub _drain_and_restore {
	my $full_method = $_[0];

	my $final_prev;
	while (@{ $mocked{$full_method} }) {
		$final_prev = pop @{ $mocked{$full_method} };
	}

	_restore_slot($full_method, $final_prev);

	return;
}

# _capture_slot -- Private helper
#
# Purpose:      Snapshot a target's CODE slot before a layer is installed.
# Entry:        $_[0] -- Str, fully-qualified sub name
# Exit:         ($existed, $saved) -- $existed is 1 if a sub with a body is
#               installed, else 0.  $saved is a reference to the current
#               CODE slot, or undef if no sub of that name has been declared
#               at all.  In the undef case \&{...} is deliberately NOT taken:
#               it would auto-vivify an empty stub, and restoring that stub
#               would shadow any inherited method of the same name.
# Side effects: None.
sub _capture_slot {
	my $full = $_[0];

	no strict 'refs';    ## no critic (ProhibitNoStrict)
	my $existed = defined(&{$full}) ? 1 : 0;
	my $saved   = exists(&{$full}) ? \&{$full} : undef;

	return ($existed, $saved);
}

# _restore_slot -- Private helper
#
# Purpose:      Put a saved CODE slot back (the inverse of _capture_slot).
# Entry:        $_[0] -- Str, fully-qualified sub name
#               $_[1] -- CodeRef saved by _capture_slot, or undef
# Exit:         undef
# Side effects: Modifies the symbol table for the target.  The GV itself is
#               never deleted (except under CORE::GLOBAL, below) because
#               compiled direct-call ops cache the GV at compile time; a new
#               GV would be invisible to them.
sub _restore_slot {
	my ($full, $prev) = @_;

	no strict 'refs';    ## no critic (ProhibitNoStrict)

	if (defined $prev) {
		no warnings 'redefine', 'prototype';
		*{$full} = $prev;
	} elsif ($full =~ /^CORE::GLOBAL::([^:]+)$/) {
		# No prior CORE::GLOBAL override existed (mock_core pushed undef).
		# Delete the stash entry entirely so Perl's builtin lookup falls back
		# to the real CORE function.  Reinstating an undef-stub CV is not
		# sufficient: Perl treats any non-NULL CV in CORE::GLOBAL as an active
		# user override, so the real builtin would never be reached.
		delete $CORE::GLOBAL::{$1};
	} else {
		# No sub was declared before the first layer went on.  Empty the CODE
		# slot while keeping the GV and its other slots, so that method lookup
		# falls through to @ISA again and a direct call dies with
		# "Undefined subroutine".  Assigning undef to a glob empties every
		# slot, so the non-CODE ones are saved and put back.
		my ($package) = $full =~ /^(.*)::[^:]+$/;
		my $gv   = \*{$full};
		my %keep = map { $_ => *{$gv}{$_} }
			grep { defined *{$gv}{$_} } qw(SCALAR ARRAY HASH IO FORMAT);
		undef *{$gv};
		*{$gv} = $keep{$_} for keys %keep;
		mro::method_changed_in($package);
	}

	return;
}

# _call_through -- Private helper
#
# Purpose:      Return the coderef a call-through wrapper (spy, before,
#               after, around, async_spy) should delegate to.
# Entry:        $_[0] -- Str, package; $_[1] -- Str, method
# Exit:         CodeRef.  If a sub of that name is declared in the package it
#               is returned directly.  Otherwise a delegator is returned that,
#               at call time, finds the method in the package's parent classes
#               (as Perl's own method lookup would once the wrapper is
#               removed) and croaks "Undefined subroutine" if there is none.
#               Taking \&{...} here instead would return a stub that re-enters
#               the wrapper through the GV and loops forever.
# Side effects: None.
sub _call_through {
	my ($package, $method) = @_;
	my $full = "${package}::${method}";

	{
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		return \&{$full} if exists &{$full};
	}

	return sub {
		my $code = _inherited_method($package, $method)
			or croak "Undefined subroutine &$full called";
		goto &$code;
	};
}

# _inherited_method -- Private helper
#
# Purpose:      Find a method in a package's ancestors, skipping the package
#               itself.
# Entry:        $_[0] -- Str, package; $_[1] -- Str, method
# Exit:         CodeRef of the first defined ancestor implementation in
#               method resolution order (UNIVERSAL last), or undef if none.
# Side effects: None.
sub _inherited_method {
	my ($package, $method) = @_;

	my (undef, @ancestors) = @{ mro::get_linear_isa($package) };
	push @ancestors, 'UNIVERSAL' unless $package eq 'UNIVERSAL';

	no strict 'refs';    ## no critic (ProhibitNoStrict)
	for my $class (@ancestors) {
		return \&{"${class}::${method}"} if defined &{"${class}::${method}"};
	}

	return;
}

# _parse_target -- Private helper
#
# Purpose:      Normalise both shorthand ('Pkg::method') and longhand
#               ('Pkg', 'method') call forms into a ($package, $method) pair.
# Entry:        @_ -- one arg for shorthand, two args for longhand
# Exit:         ($package, $method) -- list of two strings
sub _parse_target {
	my ($arg1, $arg2) = @_;

	# Shorthand: single 'Pkg::method' string -- arg2 is absent (undef)
	if (defined $arg1 && !defined $arg2 && $arg1 =~ /^(.*)::([^:]+)$/) {
		return ($1, $2);
	}

	return ($arg1, $arg2);
}

# _caller_info -- Private helper
#
# Purpose:      Walk up the call stack to find the first frame outside any
#               Test::Mockingbird namespace.  Returns a human-readable
#               "file line N" string for use in installed_at diagnostics.
#               This ensures that sugar functions (mock_return, mock_once,
#               etc.) report the user's call site, not their own location.
# Entry:        none
# Exit:         Str, e.g. "t/my_test.t line 42"
sub _caller_info {
	my $level = 1;
	while (my @info = caller($level)) {
		last unless $info[0] =~ /^Test::Mockingbird/;
		$level++;
	}
	my @info = caller($level);
	return defined $info[1] ? "$info[1] line $info[2]" : '(unknown)';
}

# _get_prototype -- Private helper
#
# Return the prototype string of a named sub, if any.
#
# Entry:        $_[0] -- Str, fully-qualified sub name
# Exit:         Str or undef
sub _get_prototype {
	my $full = $_[0];

	# All components (package segments and the sub name itself) must start
	# with a letter or underscore -- Perl identifiers cannot begin with a digit.
	croak "Invalid fully-qualified name '$full'"
		unless $full =~ /^[A-Za-z_]\w*(?:::[A-Za-z_]\w*)+$/;

	my ($pkg, $sub) = $full =~ /^(.*)::([^:]+)$/;
	my $code = $pkg->can($sub) or return;
	return prototype($code);
}

# _core_delegator -- Private helper
#
# Purpose:      Build the $call_core coderef that mock_core() passes to the
#               replacement, calling the real CORE::$name directly (which
#               bypasses any CORE::GLOBAL override).  It must be string-eval'd
#               because CORE:: names are compile-time constructs with no
#               runtime coderef.
# Entry:        $_[0] -- Str, builtin name; $_[1] -- Str|undef, its prototype
# Exit:         CodeRef.  When the prototype is a fixed list of scalar-like
#               slots (e.g. '' for time, '$$;$' for index, '*\$$;$' for read)
#               the arguments are passed by position, choosing the call by
#               argument count, since CORE::time(@_) or CORE::index(@_) does
#               not compile.  A lone '_' passes $_[0], avoiding the "Array
#               passed to stat will be coerced to a scalar" warning.  Other
#               prototypes pass @_.  If no call compiles, the delegator
#               croaks when invoked, so the builtin can still be mocked as
#               long as the replacement does not call through.
# Side effects: None.
sub _core_delegator {
	my ($name, $proto) = @_;

	my $code;
	if (defined $proto && $proto eq '_') {
		$code = "CORE::$name(\$_[0])";
	} elsif (defined $proto && $proto =~ /^((?:\\?[\$_*])*);?((?:\\?[\$_*])*)$/) {
		# Required slots, then optional ones after the ';' (if any)
		my ($req, $opt) = ($1, $2);
		my $min = () = $req =~ /[\$_*]/g;
		my $max = $min + (() = $opt =~ /[\$_*]/g);
		my @calls = map {
			my $n = $_;
			"CORE::$name(" . join(', ', map { "\$_[$_]" } 0 .. $n - 1) . ')';
		} $min .. $max;
		# Most arguments first: '@_ >= 3 ? f(a,b,c) : @_ >= 2 ? f(a,b) : f(a)'
		$code = pop @calls;
		for my $n (reverse $min .. $max - 1) {
			$code = "\@_ > $n ? $code : " . pop @calls;
		}
	} else {
		$code = "CORE::$name(\@_)";
	}

	my $sub = eval "sub { no warnings 'syntax'; $code }";  ## no critic (ProhibitStringyEval)
	return $sub if $sub;

	my $err = $@;
	return sub { croak "mock_core: cannot call through to CORE::$name: $err" };
}

# _is_name -- Private helper
#
# Purpose:      True if the argument can name a package or sub: defined and
#               non-empty.  Plain truthiness would reject the valid name '0'.
# Entry:        $_[0] -- Any
# Exit:         Bool
sub _is_name {
	return defined $_[0] && length $_[0];
}

# _is_core_overridable -- Private helper
#
# Determine whether a bare name refers to a CORE builtin that
#       Perl allows packages to shadow with a user sub.
# Entry:        $_[0] -- Str, simple identifier (no 'CORE::' prefix)
# Exit:         Bool -- true if prototype("CORE::$name") succeeds (even if
#               the returned prototype is undef, meaning "no prototype")
sub _is_core_overridable {
	my $name = $_[0];
	local $@;
	eval { my $p = prototype("CORE::$name"); 1 };
	return !$@;
}

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report bugs at L<https://github.com/nigelhorne/Test-Mockingbird/issues>.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Test-Mockingbird/coverage/>

=item * L<Test::Mockingbird::Async>

=item * L<Test::Mockingbird::DeepMock>

=item * L<Test::Mockingbird::TimeTravel>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Test-Mockingbird>

=head1 FORMAL SPECIFICATION

Notation: C<mocked[t]> is the saved-slot stack for target C<t> (head = most
recent), C<sym[t].CODE> its CODE slot, C<declared(t)> whether a sub of that
name exists in the package (C<exists &t>), and C<name(x)> means
C<defined(x) ∧ x ≠ ''>.  C<saved(t)> is C<sym[t].CODE> if C<declared(t)>,
else C<undef>.  C<resolve(p, m)> is C<sym[p::m].CODE> if C<declared(p::m)>,
else a delegator that at call time invokes the first defined C<a::m> for
C<a> in C<tail(linear_isa(p)) ⌢ ⟨UNIVERSAL⟩>, or croaks C<"Undefined
subroutine &p::m called">.

=head2 mock

    mock ≙
      ∀ pkg, meth : Str; replacement : CodeRef •
        pre  name(pkg) ∧ name(meth) ∧ ref(replacement) = 'CODE'
        let  t = pkg::meth •
        post mocked'[t] = ⟨saved(t)⟩ ⌢ mocked[t]
             ∧ sym'[t].CODE = replacement
             ∧ (saved(t) ≠ undef ⇒ prototype(replacement) = prototype(saved(t)))
             ∧ mock_meta'[t] = ⟨{ type, installed_at, original_existed }⟩ ⌢ mock_meta[t]

=head2 unmock

    unmock ≙
      ∀ t : Str •
        mocked[t] = ⟨⟩ ⇒ no change
        mocked[t] ≠ ⟨⟩ ⇒
          let prev = head(mocked[t]) •
          post mocked'[t] = tail(mocked[t]) ∧ mock_meta'[t] = tail(mock_meta[t])
               ∧ restore_slot(t, prev)

    restore_slot(t, prev) ≙
        prev ≠ undef                  ⇒ sym'[t].CODE = prev
        prev = undef ∧ t ∈ CORE::GLOBAL ⇒ t ∉ dom(stash')
        prev = undef ∧ t ∉ CORE::GLOBAL ⇒ sym'[t].CODE = ∅
                                        ∧ sym'[t] = sym[t] on every other slot
                                        ∧ t ∈ dom(stash')

=head2 before

    before ≙
      ∀ pkg, meth : Str; hook : CodeRef •
        pre  name(pkg) ∧ name(meth) ∧ ref(hook) = 'CODE'
        let orig = resolve(pkg, meth) •
          post mock(pkg::meth, wrapper)
               ∧ wrapper(@args) ≙ hook(@args); orig(@args)   -- caller's context

=head2 after

    after ≙
      ∀ pkg, meth : Str; hook : CodeRef •
        pre  name(pkg) ∧ name(meth) ∧ ref(hook) = 'CODE'
        let orig = resolve(pkg, meth) •
          post mock(pkg::meth, wrapper)
               ∧ wrapper(@args) ≙ let ret = orig(@args) • hook(@args); ret
               ∧ orig dies ⇒ hook not called

=head2 around

    around ≙
      ∀ pkg, meth : Str; hook : CodeRef •
        pre  name(pkg) ∧ name(meth) ∧ ref(hook) = 'CODE'
        let orig = resolve(pkg, meth) •
          post mock(pkg::meth, wrapper) ∧ wrapper(@args) ≙ hook(orig, @args)

=head2 mock_scoped

    mock_scoped ≙
      install all mocks via mock()
      ∧ return Guard(full_methods)
      ∧ Guard.DESTROY ⇒ ∀ m ∈ full_methods • unmock(m)

=head2 spy

    spy ≙
      ∀ pkg, meth : Str •
        pre  name(pkg) ∧ name(meth)
        let t = pkg::meth; orig = resolve(pkg, meth) •
        post mocked'[t] = ⟨saved(t)⟩ ⌢ mocked[t]
             ∧ sym'[t].CODE = wrapper ∧ prototype(wrapper) = prototype(orig)
             ∧ wrapper(@args) ≙ calls' = calls ⌢ ⟨[t, @args]⟩
                               ∧ call_log' = call_log ⌢ ⟨t⟩
                               ∧ orig(@args)
             ∧ returns sub { calls }

=head2 inject

    inject ≙
      ∀ pkg, dep : Str; val : Any •
        pre  name(pkg) ∧ name(dep)
        let t = pkg::dep •
        post mocked'[t] = ⟨saved(t)⟩ ⌢ mocked[t] ∧ sym'[t].CODE = sub { val }

=head2 inject_all

    inject_all ≙
      ∀ pkg : Str; deps : HashRef •
        post ∀ (k,v) ∈ deps • inject(pkg, k, v)

=head2 intercept_new

    intercept_new ≙
      ∀ class : Str; factory : Any •
        pre  class ≠ '' ∧ @args ≥ 2
        let  rep = (factory : CodeRef) ? factory : sub { factory } •
          post mock("${class}::new", rep)

=head2 mock_core

    mock_core ≙
      ∀ name : Str; replacement : CodeRef •
        pre  _is_core_overridable(name) ∧ ref(replacement) = 'CODE'
        let  t         = CORE::GLOBAL::name •
        let  call_core = core_delegator(name, prototype(CORE::name)) •
        let  wrapper   = sub { replacement(call_core, @_) } •
          post sym'[t].CODE = wrapper
               ∧ prototype(wrapper) = prototype(CORE::name) // '@'
               ∧ mocked'[t] = ⟨defined(sym[t].CODE) ? sym[t].CODE : undef⟩ ⌢ mocked[t]

    core_delegator(name, proto) ≙
        call_core(@a) = CORE::name(@a) with @a passed by position for a
        fixed-slot proto, as $a[0] for '_', as @a otherwise; if no such call
        compiles, call_core croaks "mock_core: cannot call through to ...".

=head2 restore_all

    restore_all ≙
      global: ∀ t ∈ dom(mocked) • restore_slot(t, last(mocked[t]))
              ∧ mocked' = {} ∧ mock_meta' = {} ∧ call_log' = []
      scoped: ∀ t ∈ dom(mocked) • t =~ /^\Qpkg\E::/ ⇒
                  restore_slot(t, last(mocked[t])) ∧ t ∉ dom(mocked') ∪ dom(mock_meta')
              ∧ call_log' = [ e ∈ call_log | e !~ /^\Qpkg\E::/ ]
              -- sub-packages (pkg::Inner::m) match; pkgX::m does not

=head2 restore

    restore ≙
      ∀ t : Str •
        pre  defined(t)
        post t ∈ dom(mocked) ⇒ restore_slot(t, last(mocked[t]))
             ∧ t ∉ dom(mocked') ∪ dom(mock_meta')

=head2 mock_return

    mock_return ≙
      ∀ target : Str; value : Any •
        post sym_table'[target].CODE = sub { value }

=head2 mock_exception

    mock_exception ≙
      ∀ target : Str; msg : Str •
        post sym_table'[target].CODE = sub { croak msg }

=head2 mock_sequence

    mock_sequence ≙
      ∀ target : Str; values : Seq(Any) •
        pre  |values| ≥ 1
        post let queue = values •
          sym_table'[target].CODE = sub { head(queue) if |queue|=1 else shift(queue) }

=head2 mock_once

    mock_once ≙
      ∀ target : Str; code : CodeRef •
        post sym_table'[target] = sub {
          result = code(@args)
          unmock(target)
          return result
        }

=head2 assert_call_order

    assert_call_order ≙
      ∀ expected : Seq(Str) •
        pre  |expected| ≥ 2
        post result = (∀ i • ∃ p_i : ℕ | p_0 < p_1 < … ∧ call_log[p_i] = expected[i])

=head2 clear_call_log

    clear_call_log ≙ post call_log' = []

=head2 diagnose_mocks

    diagnose_mocks ≙
      returns { target ↦ { depth, original_existed, layers } | target ∈ dom(mocked) }

=head2 diagnose_mocks_pretty

    diagnose_mocks_pretty ≙ stringify(diagnose_mocks())

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;

package Test::Mockingbird::Guard;

# Guard object returned by mock_scoped.  Stores a list of fully-qualified
# method names and calls unmock() on each when destroyed.

sub new {
	my ($class, @full_methods) = @_;
	return bless { full_methods => \@full_methods }, $class;
}

sub DESTROY {
	my $self = $_[0];
	Test::Mockingbird::unmock($_) for @{ $self->{full_methods} };
	return;
}

1;
