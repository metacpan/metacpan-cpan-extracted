package Test::Mockingbird;

use strict;
use warnings;
use 5.016003;

use Carp       qw(croak carp);
use Exporter   'import';
use Scalar::Util ();

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
};

our @EXPORT = qw(
	mock
	unmock
	mock_scoped
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
my %mocked;    # full_method => [ stack of coderefs (or undef stubs) ]
my %mock_meta; # full_method => [ { type => ..., installed_at => ... }, ... ]
my @call_log;  # ordered log of every spied call

=head1 NAME

Test::Mockingbird - Advanced mocking library for Perl with support for
dependency injection, spies, call ordering, constructor interception, and
async Future mocking

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

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

=head2 diagnose_mocks

Returns a structured hashref of all active mock layers.

=head2 diagnose_mocks_pretty

Returns a human-readable multi-line string of all active mock layers.

=head2 Diagnostic Metadata

Each installed layer records:

  type          -- category (mock, spy, inject, mock_return, ...)
  installed_at  -- file and line number of the outermost user call site

=head1 LIMITATIONS

=over 4

=item C<< ->can() >> may return truthy after unmocking a never-existed method

Perl's typeglob (GV) system auto-vivifies a GV entry the first time
C<\&{$full_method}> is called internally (in C<mock()>, C<spy()>, or
C<inject()>). After unmocking, this GV entry remains in the stash with an
"undefined sub" placeholder in the CODE slot. C<< Package->can('method') >>
tests the GV's existence in the stash, not whether the CODE slot is defined,
so it may still return a truthy value.

To test whether a sub is callable, use C<defined(&Package::method)> rather
than C<< Package->can('method') >>. C<defined(&...)> correctly returns false
for the placeholder stub. Calling the stub dies with C<"Undefined subroutine">.

Deleting the GV from the stash (via C<delete $stash{method}>) would make
C<< ->can() >> return false but would break subsequent mock/inject stacking:
compiled direct calls (C<Package::method()>) cache the GV at compile time,
so a new GV installed after a delete is invisible to those compiled calls.

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

=encoding utf-8

=head1 METHODS

=head2 mock

Replace a method with a coderef.

    mock('My::Module', 'method', sub { 'mocked' });
    mock 'My::Module::method' => sub { 'mocked' };

Mocks stack in LIFO order. Each C<mock()> call saves the current CODE slot
(or the auto-vivified undef stub if the method does not exist) and installs
the replacement. C<unmock()> pops one layer; C<restore_all()> drains all.

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

  "Package, method and replacement are required" -- target or coderef missing

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
		unless $package && $method && $replacement;

	my $full_method = "${package}::${method}";

	# Capture the current CODE slot (or the undef-stub if the method does
	# not yet exist).  We always capture via \& so that on restore we
	# write back to the SAME GV that compiled direct calls hold, rather
	# than deleting the GV and creating a new one that compiled ops miss.
	my ($original, $orig_existed);
	{
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		$orig_existed = defined(&{$full_method}) ? 1 : 0;
		$original     = \&{$full_method};
	}
	push @{ $mocked{$full_method} }, $original;

	# Stamp the prototype onto the replacement to avoid Perl warning about
	# "Prototype mismatch" when the original had a prototype.
	my $orig_proto = prototype($original);
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

If the method did not exist before it was mocked, the original undef-stub
is restored so that calling the method dies with C<"Undefined subroutine">.
Note: C<< ->can() >> may still return truthy; use C<defined(&...)> to test
whether a method is callable. See L</LIMITATIONS>.

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
		unless $package && $method;

	my $full_method = "${package}::${method}";

	# Nothing to do if this method was never mocked
	return unless exists $mocked{$full_method} && @{ $mocked{$full_method} };

	my $prev = pop @{ $mocked{$full_method} };

	{
		no warnings 'redefine';
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		*{$full_method} = $prev;
	}

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
		unless $package && $method && ref($hook) eq 'CODE';

	my $full_method = "${package}::${method}";
	my $orig;
	{
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		$orig = \&{$full_method};
	}

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
		unless $package && $method && ref($hook) eq 'CODE';

	my $full_method = "${package}::${method}";
	my $orig;
	{
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		$orig = \&{$full_method};
	}

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
		unless $package && $method && ref($hook) eq 'CODE';

	my $full_method = "${package}::${method}";
	my $orig;
	{
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		$orig = \&{$full_method};
	}

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

=head3 Limitation

C<spy()> does not call C<mock()> internally and therefore does not apply
prototype preservation. Wrapping a prototyped function emits a
C<Prototype mismatch> warning.

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
		unless $package && $method;

	my $full_method = "${package}::${method}";

	# Capture current implementation (or undef stub if none exists).
	# We never delete the GV; we always restore by assigning back to *{},
	# preserving the GV so compiled direct calls remain valid.
	my ($orig, $orig_existed);
	{
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		$orig_existed = defined(&{$full_method}) ? 1 : 0;
		$orig         = \&{$full_method};
	}
	push @{ $mocked{$full_method} }, $orig;

	my @calls;

	my $wrapper = sub {
		push @calls,    [ $full_method, @_ ];
		push @call_log, $full_method;
		return $orig->(@_);
	};

	{
		no warnings 'redefine';
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

  "Package and dependency are required for injection" -- missing name

=cut

sub inject {
	my ($package, $dependency, $mock_object);

	# Discriminate shorthand (2 args) from longhand (3 args) by argument
	# count rather than definedness of the third arg so that inject(Pkg,
	# Dep, undef) -- injecting undef -- is correctly handled.
	if (@_ == 2 && defined $_[0] && $_[0] =~ /^(.*)::([^:]+)$/) {
		($package, $dependency, $mock_object) = ($1, $2, $_[1]);
	} else {
		($package, $dependency, $mock_object) = @_;
	}

	croak 'Package and dependency are required for injection'
		unless $package && $dependency;

	my $full = "${package}::${dependency}";

	my ($orig, $orig_existed);
	{
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		$orig_existed = defined(&{$full}) ? 1 : 0;
		$orig         = \&{$full};
	}
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

=head2 restore_all

Restore all mocked methods and injected dependencies.

    restore_all();            # restore everything
    restore_all 'My::Module'; # restore only My::Module's mocks

When called with a package name, only mocks whose fully-qualified names
begin with that package are restored. The call-order log is pruned to
remove entries for the restored package.

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

	# Restore the original (bottom of stack) to the SAME GV that compiled
	# calls hold.  We never delete the GV because compiled direct-call ops
	# cache the GV at compile time; a new GV would be invisible to them.
	if (defined $final_prev) {
		no warnings 'redefine';
		no strict 'refs';    ## no critic (ProhibitNoStrict)
		*{$full_method} = $final_prev;
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

=head1 SUPPORT

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

=head2 mock

    mock ≙
      ∀ target : Str; replacement : CodeRef •
        pre  target ≠ '' ∧ defined(replacement)
        post mocked'[target] = ⟨saved(target)⟩ ⌢ mocked[target]
             ∧ sym_table'[target].CODE = replacement
             ∧ prototype(replacement) = prototype(saved(target))

=head2 unmock

    unmock ≙
      ∀ target : Str •
        let prev = head(mocked[target]) •
          post mocked'[target] = tail(mocked[target])
               ∧ sym_table'[target].CODE = prev
               ∧ mock_meta'[target] = tail(mock_meta[target])

=head2 before

    before ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ hook(@args); orig(@args)

=head2 after

    after ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ let ret = orig(@args) • hook(@args); ret

=head2 around

    around ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ hook(orig, @args)

=head2 mock_scoped

    mock_scoped ≙
      install all mocks via mock()
      ∧ return Guard(full_methods)
      ∧ Guard.DESTROY ⇒ ∀ m ∈ full_methods • unmock(m)

=head2 spy

    spy ≙
      ∀ target : Str •
        pre  defined(target)
        post sym_table'[target].CODE = wrapper(orig)
             ∧ wrapper: @args → (calls' = calls ⌢ ⟨[target, @args]⟩ ∧ orig(@args))

=head2 inject

    inject ≙
      ∀ pkg : Str; dep : Str; val : Any •
        pre  pkg ≠ '' ∧ dep ≠ ''
        post sym_table'["${pkg}::${dep}"].CODE = sub { val }

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

=head2 restore_all

    restore_all ≙
      global: mocked' = {} ∧ mock_meta' = {} ∧ call_log' = []
      scoped: ∀ target ∈ dom(mocked) • target =~ /^pkg::/ ⇒ unmock_all(target)
              ∧ call_log' = [ e ∈ call_log | e !~ /^pkg::/ ]

=head2 restore

    restore ≙
      ∀ target : Str •
        pre  defined(target)
        post mocked[target] = []

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
      returns { target ↦ { depth, layers } | target ∈ dom(mocked) }

=head2 diagnose_mocks_pretty

    diagnose_mocks_pretty ≙ stringify(diagnose_mocks())

=head2 before

    before ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ hook(@args); orig(@args)

=head2 after

    after ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙
                   let ret = orig(@args) •
                   hook(@args);
                   ret

=head2 around

    around ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ hook(orig, @args)

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
