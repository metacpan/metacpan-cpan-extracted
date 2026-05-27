package Test::MockModule;
use warnings;
use strict qw/subs vars/;
use vars qw/$VERSION/;
use Scalar::Util qw/reftype refaddr weaken/;
use Carp;
use SUPER;
# This is now auto-updated at release time by the github action
$VERSION = '0.185.1';

our $GLOBAL_STRICT_MODE;

sub import {
    my ( $class, @args ) = @_;

    # default if no args
    $^H{'Test::MockModule/STRICT_MODE'} = 0;

    foreach my $arg (@args) {
        if($arg eq 'global-strict' ) {
            $GLOBAL_STRICT_MODE=1;
            $^H{'Test::MockModule/STRICT_MODE'} = 1;
        }
        elsif ( $arg eq 'strict' ) {
            $^H{'Test::MockModule/STRICT_MODE'} = 1;
        } elsif ( $arg eq 'nostrict' ) {
            $GLOBAL_STRICT_MODE && die "use Test::MockModule qw(nostrict) is illegal when GLOBAL_STRICT_MODE is being enforced";
            $^H{'Test::MockModule/STRICT_MODE'} = 0;
        } else {
            carp "Test::MockModule unknown import option '$arg'";
        }
    }
    return;
}

sub _strict_mode {
    my $depth = 0;
    while(my @fields = caller($depth++)) {
        my $hints = $fields[10];
        if($hints && exists $hints->{'Test::MockModule/STRICT_MODE'}) {
            $GLOBAL_STRICT_MODE && !$hints->{'Test::MockModule/STRICT_MODE'} && die "use Test::MockModule qw(nostrict) is illegal when GLOBAL_STRICT_MODE is being enforced";

            return $hints->{'Test::MockModule/STRICT_MODE'};
        }
    }
    return 0;
}

# Per-sub stack of live mock layers. Each entry:
#   { id, orig, installed, is_meta, meta_orig }
#
#   id        = refaddr of the mock object owning the layer.
#   orig      = coderef at *Pkg::sub immediately before this layer was pushed
#                (or undef if no sub existed). On mid-stack unmock, the popped
#                entry's orig cascades down to the next layer so the eventual
#                stack-empty restore sees the right "pre-mock" state.
#   installed = coderef this layer most recently installed. Updated on
#                re-mock by the same object so that an above-layer unmock,
#                or a mid-stack splice, can re-install the latest coderef.
#   is_meta   = true if this layer was pushed while the package's metaclass
#                was mutable (Moose Class::MOP::Class or Mouse::Meta::Class).
#                Drives whether unmock restores via meta->add_method or via
#                the symbol table.
#   meta_orig = Method object (or undef) returned by $meta->get_method($name)
#                immediately before this layer was pushed; only meaningful
#                when is_meta is true. Cascaded on mid-stack unmock the same
#                way as orig, so the bottom-of-stack restore can use the
#                correct pre-any-mock meta state.
my %mock_subs;

# Per-package weak registry: keeps the singleton-per-package behavior
# that was the default prior to v0.181 (and the documented contract for
# the `$mock->original` from-inside-closure pattern). new() returns
# the existing object for a package if one is alive; weak ref so a
# cleanly-destroyed mock releases the slot naturally. Pass
# `distinct => 1` to opt out and get a fresh object per call (the
# v0.181+ GH #48 behavior).
my %singleton;

sub new {
	my ($class, $package, %args) = @_;

	croak "Cannot mock $package" if $package && $class && $package eq $class;
	unless (_valid_package($package)) {
		$package = 'undef' unless defined $package;
		croak "Invalid package name $package";
	}

	# Auto-load the package BEFORE consulting the singleton cache.
	# Otherwise a singleton seeded by an earlier `no_auto => 1` caller
	# would silently deny later default-mode callers the module load
	# they expect from `new()` (Koan-Bot review on PR #85).
	unless ($package eq "CORE::GLOBAL" || $package eq 'main' || $args{no_auto} || ${"$package\::VERSION"}) {
		(my $load_package = "$package.pm") =~ s{::}{/}g;
		TRACE("$package is empty, loading $load_package");
		require $load_package;
	}

	if (!$args{distinct} && $singleton{$package}) {
		TRACE("Reusing singleton MockModule object for $package");
		return $singleton{$package};
	}

	TRACE("Creating MockModule object for $package");
	my $self = bless {
		_package => $package,
		_mocked  => {},
	}, $class;

	if (!$args{distinct}) {
		$singleton{$package} = $self;
		weaken($singleton{$package});
	}

	return $self;
}

sub DESTROY {
	my $self = shift;
	$self->unmock_all;
}

sub get_package {
	my $self = shift;
	return $self->{_package};
}

sub redefine {
	my ($self, @mocks) = (@_);

	my @mocks_copy = @mocks;
	while ( my ($name, $value) = splice @mocks_copy, 0, 2 ) {
		my $sub_name = $self->_full_name($name);
		my $coderef = *{$sub_name}{'CODE'};
		next if 'CODE' eq ref $coderef;

		if ( $sub_name =~ qr{^(.+)::([^:]+)$} ) {
			my ( $pkg, $sub ) = ( $1, $2 );
			next if $pkg->can( $sub );
		}

		if ('CODE' ne ref $coderef) {
			croak "$sub_name does not exist!";
		}
	}

	return $self->_mock(@mocks);
}

sub define {
	my ($self, @mocks) = @_;

	my @mocks_copy = @mocks;
	while ( my ($name, $value) = splice @mocks_copy, 0, 2 ) {
		my $sub_name = $self->_full_name($name);
		my $coderef = *{$sub_name}{'CODE'};

		if ('CODE' eq ref $coderef) {
			croak "$sub_name exists!";
		}
	}

	my $ret = $self->_mock(@mocks);

	# Mark defined subs so _mock() can update _orig on redefine (GH #64)
	while ( my ($name, $value) = splice @mocks, 0, 2 ) {
		$self->{_defined}{$name} = 1;
	}

	return $ret;
}

sub mock {
	my ($self, @mocks) = @_;

	croak "mock is not allowed in strict mode. Please use define or redefine" if $self->_strict_mode();

	return $self->_mock(@mocks);
}

sub _mock {
	my $self = shift;

	# Lazily load Class::MOP::Method once if the target is a Moose class.
	# Class::MOP is already loaded transitively whenever the target uses Moose,
	# so this require is essentially a hash-lookup; we still hoist it out of
	# the per-name install loop for clarity.
	{
		my $meta = _meta_for($self->{_package});
		require Class::MOP::Method if $meta && $meta->isa('Class::MOP::Class');
	}

	while (my ($name, $value) = splice @_, 0, 2) {
		my $code = sub { };
		if (ref $value && reftype $value eq 'CODE') {
			$code = $value;
		} elsif (defined $value) {
			$code = sub {$value};
		}

		TRACE("$name: $code");
		croak "Invalid subroutine name: $name" unless _valid_subname($name);
		my $sub_name = _full_name($self, $name);
		my $meta     = _meta_for($self->{_package});
		my $can_meta = $meta && !$meta->is_immutable;

		if (!$self->{_mocked}{$name}) {
			TRACE("Storing existing $sub_name");
			$self->{_mocked}{$name} = 1;
			my $orig = defined &{$sub_name} ? \&$sub_name : undef;
			$self->{_orig}{$name} = $orig;
			# get_method() can return an empty list (rather than undef) for
			# methods that aren't locally defined; force scalar context so
			# the anonymous hash gets exactly one value here.
			my $meta_orig = $can_meta ? scalar $meta->get_method($name) : undef;
			$mock_subs{$sub_name} ||= [];
			push @{$mock_subs{$sub_name}}, {
				id        => refaddr($self),
				orig      => $orig,
				installed => $code,
				is_meta   => $can_meta ? 1 : 0,
				meta_orig => $meta_orig,
			};
		} else {
			my $is_redefine_after_define = $self->{_defined}{$name};
			delete $self->{_defined}{$name} if $is_redefine_after_define;

			# Re-mock by same object: update our stack entry's installed
			# coderef so an above-layer unmock cascades to the correct
			# (current) coderef. GH #64: when this is a redefine of a sub
			# created via define(), also update _orig and the entry's orig
			# so unmock() restores the originally-defined sub. Use this
			# layer's PRIOR installed coderef rather than \&{$sub_name} --
			# with stacking, the symbol may currently hold another mock
			# object's installed coderef rather than ours.
			if (my $stack = $mock_subs{$sub_name}) {
				my $my_id = refaddr($self);
				for my $entry (@$stack) {
					if ($entry->{id} == $my_id) {
						if ($is_redefine_after_define) {
							my $prior = $entry->{installed};
							$self->{_orig}{$name} = $prior;
							$entry->{orig} = $prior;
						}
						$entry->{installed} = $code;
						last;
					}
				}
			}
		}

		if ($can_meta) {
			TRACE("Installing mocked $sub_name via meta->add_method");
			if ($meta->isa('Class::MOP::Class')) {
				$meta->add_method(
					$name,
					Class::MOP::Method->wrap(
						$code,
						name         => $name,
						package_name => $self->{_package},
					),
				);
			} else {
				# Mouse: add_method accepts a plain coderef and wraps internally
				$meta->add_method($name, $code);
			}
		} else {
			if ($meta && $meta->is_immutable && !$self->{_warned_immutable}{$name}) {
				$self->{_warned_immutable}{$name} = 1;
				carp sprintf(
					"Test::MockModule: package %s is immutable; mocking %s via symbol table only. "
					. "Moose role/modifier resolution will not see the mock. "
					. "Call %s->meta->make_mutable before mocking if MOP-aware behavior is needed.",
					$self->{_package}, $name, $self->{_package},
				);
			}
			TRACE("Installing mocked $sub_name");
			_replace_sub($sub_name, $code);
		}
	}

	return $self;
}

# Install $entry->{installed} at *Pkg::$name, using the meta path when the
# entry was originally pushed via meta and the metaclass is currently mutable;
# otherwise fall back to the symbol table.
sub _install_layer {
	my ($self, $sub_name, $name, $entry) = @_;
	my $meta = _meta_for($self->{_package});
	if ($entry->{is_meta} && $meta && !$meta->is_immutable) {
		if ($meta->isa('Class::MOP::Class')) {
			$meta->add_method(
				$name,
				Class::MOP::Method->wrap(
					$entry->{installed},
					name         => $name,
					package_name => $self->{_package},
				),
			);
		} else {
			$meta->add_method($name, $entry->{installed});
		}
	} else {
		_replace_sub($sub_name, $entry->{installed});
	}
}

# Restore the pre-any-mock state for the bottom-most (and now only) layer
# being popped. Uses the entry's meta_orig when the layer was pushed via
# meta, otherwise its symbol-table orig coderef.
sub _restore_pre_mock {
	my ($self, $sub_name, $name, $entry) = @_;
	my $meta = _meta_for($self->{_package});
	my $can_meta = $meta && !$meta->is_immutable;

	if ($entry->{is_meta} && $can_meta) {
		my $orig_method = $entry->{meta_orig};
		if (defined $orig_method) {
			TRACE("Restoring original $sub_name via meta->add_method");
			# Older Mouse versions require a coderef and reject a
			# Mouse::Meta::Method object; extract the body for Mouse.
			# Moose accepts either a coderef or a Class::MOP::Method.
			my $arg = $meta->isa('Mouse::Meta::Class')
				? (ref($orig_method) eq 'CODE' ? $orig_method : $orig_method->body)
				: $orig_method;
			$meta->add_method($name, $arg);
		} else {
			TRACE("Removing mocked $sub_name from meta (was inherited or absent)");
			if ($meta->can('remove_method')) {
				$meta->remove_method($name);
			} else {
				# Mouse::Meta::Class has no remove_method; purge the
				# internal methods cache entry directly so that
				# get_method() no longer finds the mocked entry.
				delete $meta->{methods}{$name};
			}
			# remove_method does not always clear the symbol table.
			# When the layer captured a symbol-table orig (e.g. an earlier
			# layer pushed via the symbol table while meta was immutable,
			# then make_mutable purged the cached meta entry), restore that
			# coderef so the method continues to resolve. When orig is
			# undef the slot is cleared, so direct calls fall through to
			# AUTOLOAD/parent.
			_replace_sub($sub_name, $entry->{orig});
		}
	} else {
		# Either the layer was a symbol-table push, or meta became immutable
		# between mock and unmock. Fall back to the captured orig coderef.
		_replace_sub($sub_name, $entry->{orig});
	}
}

sub noop {
    my $self = shift;

    croak "noop is not allowed in strict mode. Please use define or redefine" if $self->_strict_mode();

    $self->_mock($_,1) for @_;

    return;
}

sub mock_all {
	my ($self, %opts) = @_;

	croak "mock_all is not allowed in strict mode. Please use redefine" if $self->_strict_mode();

	my $package = $self->{_package};

	my @subs;
	{
		no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
		@subs = sort grep {
			defined &{"${package}::$_"}
		} keys %{"${package}::"};
	}

	my $make_handler = exists $opts{handler}
		? sub { $opts{handler} }
		: $opts{noop}
			? sub { sub { 1 } }
			: sub { my $n = shift; sub { croak "$n was not mocked" } };

	# Skip special Perl subs that should never be blindly mocked:
	# - Phase blocks (BEGIN, END, INIT, CHECK, UNITCHECK) run at compile/exit time
	# - DESTROY is called during object cleanup
	# - AUTOLOAD handles missing method dispatch
	# - import handles use/import semantics
	# - Overload subs start with '(' (e.g. '(""', '(+', '(==')
	my %_skip = map { $_ => 1 } qw(
		import DESTROY BEGIN END INIT CHECK UNITCHECK AUTOLOAD
	);

	my @to_mock;
	for my $name (@subs) {
		next if $_skip{$name};
		next if $name =~ /^\(/;  # overload subs
		next if $self->{_mocked}{$name};
		push @to_mock, $name, $make_handler->("${package}::${name}");
	}

	return $self->_mock(@to_mock) if @to_mock;
	return $self;
}

sub original {
	my ($self, $name) = @_;

	carp 'Please provide a valid function name' unless _valid_subname($name);

	unless ($self->{_mocked}{$name}) {
		# GH #42: when not mocked, return the actual sub instead of warning
		my $sub_name = _full_name($self, $name);
		return \&$sub_name if defined &{$sub_name};
		return $self->{_package}->super($name);
	}
	return defined $self->{_orig}{$name} ? $self->{_orig}{$name} : $self->{_package}->super($name);
}

# Class-method counterpart to $mock->original(). Takes strings, returns
# the truly-original coderef from the per-package registry (or the live
# sub if not mocked). Lets user closures reach the original sub without
# capturing $mock -- the closure-capture pattern that drives the GH #83
# DESTROY-leak under `distinct => 1` mode.
sub original_for {
	my ($class, $package, $name) = @_;
	croak "Invalid package name " . (defined $package ? $package : 'undef')
		unless _valid_package($package);
	croak 'Please provide a valid function name'
		unless _valid_subname($name);

	my $sub_name = "${package}::${name}";
	my $stack = $mock_subs{$sub_name};
	if ($stack && @$stack) {
		# Bottom-of-stack orig is the truly-original. May be undef when
		# the sub was created via define() -- that is expected. Falling
		# through to \&$sub_name would hand back the active mock (an
		# infinite-recursion footgun for closures wrapping their orig).
		return $stack->[0]{orig};
	}
	no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
	return \&$sub_name if defined &{$sub_name};
	return;
}

sub unmock {
	my ( $self, @names ) = @_;

	carp 'Nothing to unmock' unless @names;
	for my $name (@names) {
		croak "Invalid subroutine name: $name" unless _valid_subname($name);

		my $sub_name = _full_name($self, $name);
		unless ($self->{_mocked}{$name}) {
			carp $sub_name . " was not mocked";
			next;
		}

		TRACE("Restoring original $sub_name");
		my $stack = $mock_subs{$sub_name};
		if ($stack) {
			my $my_id = refaddr($self);
			my $idx;
			for my $i (0 .. $#$stack) {
				if ($stack->[$i]{id} == $my_id) {
					$idx = $i;
					last;
				}
			}
			if (defined $idx) {
				if ($idx == $#$stack) {
					# Top of stack: restore the prior layer's installed
					# coderef (via meta or symbol as the layer dictates),
					# or fully restore the pre-mock state if no prior
					# layer remains.
					my $popped = pop @$stack;
					if (@$stack) {
						$self->_install_layer($sub_name, $name, $stack->[-1]);
					} else {
						$self->_restore_pre_mock($sub_name, $name, $popped);
					}
				} else {
					# Mid-stack: cascade our orig (and meta_orig, when the
					# layer above also used the meta path) down to the next
					# entry so a later stack-empty restore sees the correct
					# pre-any-mock state. Then remove ourselves and re-install
					# the new top's installed coderef -- the symbol/meta may
					# currently hold OUR installed coderef if we re-mocked
					# after a higher layer was pushed, so we must explicitly
					# restore the layer that should now be active.
					$stack->[$idx + 1]{orig} = $stack->[$idx]{orig};
					$stack->[$idx + 1]{meta_orig} = $stack->[$idx]{meta_orig}
						if $stack->[$idx + 1]{is_meta};
					splice @$stack, $idx, 1;
					$self->_install_layer($sub_name, $name, $stack->[-1]);
				}
			} else {
				# Defensive: not found in stack (shouldn't happen).
				_replace_sub($sub_name, $self->{_orig}{$name});
			}
			delete $mock_subs{$sub_name} unless @$stack;
		} else {
			_replace_sub($sub_name, $self->{_orig}{$name});
		}

		delete $self->{_mocked}{$name};
		delete $self->{_orig}{$name};
		delete $self->{_defined}{$name};
		delete $self->{_warned_immutable}{$name};
	}
	return $self;
}

sub unmock_all {
	my $self = shift;
	foreach my $name (keys %{$self->{_mocked}}) {
		$self->unmock($name);
	}

	return;
}

sub is_mocked {
	my ($self, $name) = @_;

	return unless _valid_subname($name);

	return $self->{_mocked}{$name};
}

sub mocked_subs {
	my $self = shift;
	my @subs = sort keys %{$self->{_mocked}};
	return @subs;
}

sub _full_name {
	my ($self, $sub_name) = @_;
	return sprintf( "%s::%s", $self->{_package}, $sub_name );
}

sub _valid_package {
	my $name = shift;
	return unless defined $name && length $name;
	return $name =~ /^[a-z_]\w*(?:::\w+)*$/i;
}

sub _valid_subname {
	my $name = shift;
	return unless defined $name && length $name;
	return $name =~ /^[a-z_]\w*$/i;
}

sub _meta_for {
	my $package = shift;
	return unless defined $package && length $package;
	return unless $package->can('meta');
	my $meta = eval { $package->meta };
	return unless ref $meta;
	return $meta if $meta->isa('Class::MOP::Class');   # Moose
	return $meta if $meta->isa('Mouse::Meta::Class');  # Mouse
	return;
}

sub _replace_sub {
	my ($sub_name, $coderef) = @_;

    no warnings qw< redefine prototype >;

	if (defined $coderef) {
		*{$sub_name} = $coderef;
	} else {
		TRACE("removing subroutine: $sub_name");
		my ($package, $sub) = $sub_name =~ /(.*::)(.*)/;
		my %symbols = %{$package};

		# save a copy of all non-code slots
		my %slot;
		foreach my $slot_name (qw(ARRAY FORMAT HASH IO SCALAR)) {
			next unless defined $symbols{$sub};
			next unless defined(my $elem = *{$symbols{$sub}}{$slot_name});
			$slot{$slot_name} = $elem;
		}

		# clear the symbol table entry for the subroutine
		undef *$sub_name;

		# restore everything except the code slot
		return unless scalar keys %slot;
		foreach (keys %slot) {
			*$sub_name = $slot{$_};
		}
	}
}

# Log::Trace stubs
sub TRACE {}
sub DUMP  {}

1;

=pod

=head1 NAME

Test::MockModule - Override subroutines in a module for unit testing

=head1 SYNOPSIS

	use Module::Name;
	use Test::MockModule;

	{
		my $module = Test::MockModule->new('Module::Name');
		$module->mock('subroutine', sub { ... });
		Module::Name::subroutine(@args); # mocked

		# Same effect, but this will die() if other_subroutine()
		# doesn't already exist, which is often desirable.
		$module->redefine('other_subroutine', sub { ... });

		# This will die() if another_subroutine() is defined.
		$module->define('another_subroutine', sub { ... });
	}

	{
		# you can also chain new/mock/redefine/define

		Test::MockModule->new('Module::Name')
		->mock( one_subroutine => sub { ... })
		->redefine( other_subroutine => sub { ... } )
		->define( a_new_sub => 1234 );
	}

	Module::Name::subroutine(@args); # original subroutine

	# Working with objects
	use Foo;
	use Test::MockModule;
	{
		my $mock = Test::MockModule->new('Foo');
		$mock->mock(foo => sub { print "Foo!\n"; });

		my $foo = Foo->new();
		$foo->foo(); # prints "Foo!\n"
	}

    # If you want to prevent noop and mock from working, you can
    # load Test::MockModule in strict mode.

    use Test::MockModule qw/strict/;
    my $module = Test::MockModule->new('Module::Name');

    # Redefined the other_subroutine or dies if it's not there.
    $module->redefine('other_subroutine', sub { ... });

    # Dies since you specified you wanted strict mode.
    $module->mock('subroutine', sub { ... });

    # Turn strictness off in this lexical scope
    {
        use Test::MockModule 'nostrict';
        # ->mock() works now
        $module->mock('subroutine', sub { ... });
    }

	# Assure strict is ALWAYS used.
	use Test::MockModule 'global-strict';

    # Back in the strict scope, so mock() dies here
    $module->mock('subroutine', sub { ... });

=head1 DESCRIPTION

C<Test::MockModule> lets you temporarily redefine subroutines in other packages
for the purposes of unit testing.

A C<Test::MockModule> object is set up to mock subroutines for a given
module. The object remembers the original subroutine so it can be easily
restored. This happens automatically when all MockModule objects for the given
module go out of scope, or when you C<unmock()> the subroutine.

=head1 STRICT MODE

One of the weaknesses of testing using mocks is that the implementation of the
interface that you are mocking might change, while your mocks get left alone.
You are not now mocking what you thought you were, and your mocks might now be
hiding bugs that will only be spotted in production. To help prevent this you
can load Test::MockModule in 'strict' mode:

    use Test::MockModule qw(strict);

This will disable use of the C<mock()> method, making it a fatal runtime error.
You should instead define mocks using C<redefine()>, which will only mock
things that already exist and die if you try to redefine something that doesn't
exist.

Strictness is lexically scoped, so you can do this in one file:

    use Test::MockModule qw(strict);
    
    ...->redefine(...);

and this in another:

    use Test::MockModule; # the default is nostrict

    ...->mock(...);

You can even mix n match at different places in a single file thus:

    use Test::MockModule qw(strict);
    # here mock() dies

    {
        use Test::MockModule qw(nostrict);
        # here mock() works
    }

    # here mock() goes back to dieing

    use Test::MockModule qw(nostrict);
    # and from here on mock() works again

NB that strictness must be defined at compile-time, and set using C<use>. If
you think you're going to try and be clever by calling Test::MockModule's
C<import()> method at runtime then what happens in undefined, with results
differing from one version of perl to another. What larks!

=head1 GLOBAL STRICT MODE

If your particular test suite needs to assure that no developer ever accidentally
turns off strict, this is the mode for you

	use Test::MockModule 'global-strict';

Setting this mode will cause any later invocation of nostrict to fail on compile.
Further, any use of mock at runtime will die if the 'nostrict' mode was invoked
prior to global-strict being initially set. While this seems like it might be
overkill, this can be important as the number of simultaneous developers
increases over time.

=head1 METHODS

=over 4

=item new($package[, %options])

Returns a singleton-per-package mock object. Two calls to
C<< Test::MockModule->new('Foo') >> return the same object as long as the
first one is still alive; this preserves the long-standing pre-v0.181
contract that the documented C<< $mock->original >> from-inside-closure
pattern depends on (see GH #83).

Pass C<< distinct => 1 >> to opt into the v0.181 GH #48 semantics --
each call returns a fresh object, multiple mock objects coexist on the
same package, and the per-sub stack handles multi-mock layering:

	my $m1 = Test::MockModule->new('Module::Name', distinct => 1);
	my $m2 = Test::MockModule->new('Module::Name', distinct => 1);
	# $m1 and $m2 are independent. Tests that need this layering must
	# opt in explicitly.

Under C<distinct> mode the most recent C<mock>/C<redefine> call wins
regardless of stack position; when a mock object is destroyed, the
layer below it on the stack is reactivated; when all mock objects for
a subroutine are destroyed, the original subroutine is restored.

If there is no C<$VERSION> defined in C<$package>, the module will be
automatically loaded. You can override this behaviour by setting the
C<no_auto> option:

	my $mock = Test::MockModule->new('Module::Name', no_auto => 1);

B<GH #83 caveat for distinct mode>: a closure that captures C<$mock>
(typically by calling C<< $mock->original(...) >> inside the mock body)
prevents C<DESTROY> from firing when C<$mock> goes out of scope, so
the mock leaks past its lexical scope. The default (singleton) mode
makes this leak harmless by re-using the same object on subsequent
C<new()> calls. Under C<< distinct => 1 >>, prefer the class-method
form C<< Test::MockModule->original_for($pkg, $sub) >> from inside
closures so they capture only strings, or capture
C<< $mock->original(...) >> in a lexical B<before> calling C<mock()>.

=item get_package()

Returns the target package name for the mocked subroutines

=item is_mocked($subroutine)

Returns a boolean value indicating whether or not the subroutine is currently
mocked

=item mocked_subs()

Returns a sorted list of the subroutine names that are currently mocked for
this module. Useful for debugging complex test setups.

	my $mock = Test::MockModule->new('Module::Name');
	$mock->mock('foo', sub { 1 });
	$mock->mock('bar', sub { 2 });
	my @mocked = $mock->mocked_subs; # ('bar', 'foo')

=item mock($subroutine =E<gt> \E<amp>coderef)

Temporarily replaces one or more subroutines in the mocked module. A subroutine
can be mocked with a code reference or a scalar. A scalar will be recast as a
subroutine that returns the scalar.

Returns the current C<Test::MockModule> object, so you can chain L<new> with L<mock>.

	my $mock = Test::MockModule->new(...)->mock(...);

The following statements are equivalent:

	$module->mock(purge => 'purged');
	$module->mock(purge => sub { return 'purged'});

When dealing with references, things behave slightly differently. The following
statements are B<NOT> equivalent:

	# Returns the same arrayref each time, with the localtime() at time of mocking
	$module->mock(updated => [localtime()]);
	# Returns a new arrayref each time, with up-to-date localtime() value
	$module->mock(updated => sub { return [localtime()]});

The following statements are in fact equivalent:

	my $array_ref = [localtime()]
	$module->mock(updated => $array_ref)
	$module->mock(updated => sub { return $array_ref });


However, C<undef> is a special case. If you mock a subroutine with C<undef> it
will install an empty subroutine

	$module->mock(purge => undef);
	$module->mock(purge => sub { });

rather than a subroutine that returns C<undef>:

	$module->mock(purge => sub { undef });

You can call C<mock()> for the same subroutine many times, but when you call
C<unmock()>, the original subroutine is restored (not the last mocked
instance).

B<MOCKING + EXPORT>

If you are trying to mock a subroutine exported from another module, this may
not behave as you initially would expect, since Test::MockModule is only mocking
at the target module, not anything importing that module. If you mock the local
package, or use a fully qualified function name, you will get the behavior you
desire:

	use Test::MockModule;
	use Test::More;
	use POSIX qw/strftime/;

	my $posix = Test::MockModule->new("POSIX");

	$posix->mock("strftime", "Yesterday");
	is strftime("%D", localtime(time)), "Yesterday", "`strftime` was mocked successfully"; # Fails
	is POSIX::strftime("%D", localtime(time)), "Yesterday", "`strftime` was mocked successfully"; # Succeeds

	my $main = Test::MockModule->new("main", no_auto => 1);
	$main->mock("strftime", "today");
	is strftime("%D", localtime(time)), "today", "`strftime` was mocked successfully"; # Succeeds

If you are trying to mock a subroutine that was exported into a module that you're
trying to test, rather than mocking the subroutine in its originating module,
you can instead mock it in the module you are testing:

	package MyModule;
	use POSIX qw/strftime/;

	sub minus_twentyfour
	{
		return strftime("%a, %b %d, %Y", localtime(time - 86400));
	}

	package main;
	use Test::More;
	use Test::MockModule;

	my $posix = Test::MockModule->new("POSIX");
	$posix->mock("strftime", "Yesterday");

	is MyModule::minus_twentyfour(), "Yesterday", "`minus-twentyfour` got mocked"; # fails

	my $mymodule = Test::MockModule->new("MyModule", no_auto => 1);
	$mymodule->mock("strftime", "Yesterday");
	is MyModule::minus_twentyfour(), "Yesterday", "`minus-twentyfour` got mocked"; # succeeds

=item redefine($subroutine)

The same behavior as C<mock()>, but this will preemptively check to be
sure that all passed subroutines actually exist. This is useful to ensure that
if a mocked module's interface changes the test doesn't just keep on testing a
code path that no longer behaves consistently with the mocked behavior.

Note that redefine is also now checking if one of the parent provides the sub
and will not die if it's available in the chain.

Returns the current C<Test::MockModule> object, so you can chain L<new> with L<redefine>.

	my $mock = Test::MockModule->new(...)->redefine(...);

=item define($subroutine)

The reverse of redefine, this will fail if the passed subroutine exists.
While this use case is rare, there are times where the perl code you are
testing is inspecting a package and adding a missing subroutine is actually
what you want to do.

By using define, you're asserting that the subroutine you want to be mocked
should not exist in advance.

Note: define does not check for inheritance like redefine.

Returns the current C<Test::MockModule> object, so you can chain L<new> with L<define>.

	my $mock = Test::MockModule->new(...)->define(...);

=item original($subroutine)

Returns the original (unmocked) subroutine. If the subroutine is not currently
mocked, returns the existing subroutine directly instead of warning. This makes
it safe to call C<original()> before or after mocking.

Here is a sample how to wrap a function with custom arguments using the original subroutine.
This is useful when you cannot (do not) want to alter the original code to abstract
one hardcoded argument pass to a function.

	package MyModule;

	sub sample {
		return get_path_for("/a/b/c/d");
	}

	sub get_path_for {
		... # anything goes there...
	}

	package main;
	use Test::MockModule;

	my $mock = Test::MockModule->new("MyModule");
	# capture the original before mocking to avoid closing over $mock
	my $orig_get_path = $mock->original("get_path_for");
	# replace all calls to get_path_for using a different argument
	$mock->redefine("get_path_for", sub {
		return $orig_get_path->("/my/custom/path");
	});

	# or

	my $orig_get_path = $mock->original("get_path_for");
	$mock->redefine("get_path_for", sub {
		my $path = shift;
		if ( $path && $path eq "/a/b/c/d" ) {
			# only alter calls with path set to "/a/b/c/d"
			return $orig_get_path->("/my/custom/path");
		} else { # preserve the original arguments
			return $orig_get_path->($path, @_);
		}
	});


=item original_for($package, $subroutine)

Class-method counterpart to C<original()>. Returns the truly-original
coderef for C<$package::$subroutine> from the per-package registry,
or the live sub via the symbol table if not currently mocked. Returns
C<undef> if no sub by that name exists. Croaks on invalid package or
sub names.

The motivating use case is letting closures reach the original sub
without capturing C<$mock> -- the closure-capture pattern that drives
the GH #83 leak under C<< distinct => 1 >> mode:

	my $mock = Test::MockModule->new('MyModule', distinct => 1);
	$mock->mock('greet', sub {
		# Closure captures only strings -- $mock can be GC'd at scope end
		return Test::MockModule
			->original_for('MyModule', 'greet')->(@_) . '_suffix';
	});

For stacked mocks, returns the truly-original (pre-any-mock) coderef,
not the layer below.


=item unmock($subroutine [, ...])

Restores the original C<$subroutine>. You can specify a list of subroutines to
C<unmock()> in one go.

=item unmock_all()

Restores all the subroutines in the package that were mocked. This is
automatically called when all C<Test::MockModule> objects for the given package
go out of scope.

=item noop($subroutine [, ...])

Given a list of subroutine names, mocks each of them with a no-op subroutine that
returns C<1>. Handy for mocking methods you want to ignore!

The C<1> return value is part of the public contract of this method (see GH #81)
-- callers in the wild rely on it being truthy.

    # Neuter a list of methods in one go
    $module->noop('purge', 'updated');

=item mock_all(%options)

Mocks all subroutines in the target package that are not already mocked.
By default, each mocked subroutine will die when called, making it easy
to catch unexpected calls during testing.

    my $module = Test::MockModule->new('Foo');
    $module->mock_all();
    Foo->bar();  # dies: "Foo::bar was not mocked"

The C<import> subroutine is always skipped.

Options:

=over 4

=item noop =E<gt> 1

Mock all subroutines with a no-op sub that returns C<1> instead of dying.
This is consistent with C<noop()>.

    $module->mock_all(noop => 1);
    Foo->bar();  # returns 1

=item handler =E<gt> \&coderef

Provide a custom handler for all mocked subroutines.

    $module->mock_all(handler => sub { warn "unexpected call" });

=back

Returns the current C<Test::MockModule> object for chaining.

=back

=over 4

=item TRACE

A stub for Log::Trace

=item DUMP

A stub for Log::Trace

=back

=head1 MOOSE AND MOUSE SUPPORT

When the target package's metaclass is a C<Class::MOP::Class> (Moose) or
C<Mouse::Meta::Class> (Mouse), C<Test::MockModule> registers mocks with
the meta-object via C<add_method> in addition to installing them in the
symbol table. This makes mocked methods visible to:

=over 4

=item * Moose role C<requires> checks (including dynamic role application
via L<Moose::Util/apply_all_roles>).

=item * Method modifier resolution (C<around>, C<before>, C<after>) on
subclasses loaded after the mock is installed.

=item * Other MOP-driven introspection that walks C<get_method> /
C<get_method_list>.

=back

C<unmock> reverses the registration: if the original method existed on
the class itself, it is restored via C<add_method>; if the method was
inherited (or absent) before mocking, it is removed via
C<remove_method> so inheritance lookup falls back to the parent.
For Mouse classes (which lack a public C<remove_method> on
C<Mouse::Meta::Class>), the mock entry is purged from the meta-class's
internal method cache directly to achieve the same effect.

If the target class is immutable (C<< $meta->is_immutable >> is true),
C<Test::MockModule> falls back to symbol-table-only behavior and emits a
warning. Call C<< Pkg->meta->make_mutable >> before mocking if you need
MOP-aware behavior on an immutable class.

=head2 Moo and other MOP-less object systems

L<Moo>, L<Role::Tiny>, and L<Object::Pad> are not detected and not
specially handled. Mocks on Moo classes still work for direct calls but
will not be seen by role-application or method-modifier resolution for
classes that consume Moo roles. As a workaround, mock the underlying
package directly with C<no_auto =E<gt> 1> and explicit load ordering, or
convert the affected class to Moose.

=head1 SEE ALSO

L<Test::MockObject::Extends>

L<Sub::Override>

=head1 AUTHORS

Current Maintainer: Geoff Franks <gfranks@cpan.org>

Original Author: Simon Flack E<lt>simonflk _AT_ cpan.orgE<gt>

Lexical scoping of strictness: David Cantrell E<lt>david@cantrell.org.ukE<gt>

=head1 COPYRIGHT

Copyright 2004 Simon Flack E<lt>simonflk _AT_ cpan.orgE<gt>.
All rights reserved

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

=cut
