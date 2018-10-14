package Test::Trap::Builder;

use version; $VERSION = qv('0.3.4');

use strict;
use warnings;
use Data::Dump qw(dump);
BEGIN {
  use Exporter ();
  *import = \&Exporter::import;
  my @methods = qw( Next Exception ExceptionFunction Teardown Run TestAccessor TestFailure Prop DESTROY );
  our @EXPORT_OK = (@methods);
  our %EXPORT_TAGS = ( methods => \@methods );
}
use constant GOT_CARP_NOT => $] >= 5.008;
use Carp qw(croak);
our (@CARP_NOT, @ISA);

my $builder = bless {};

# Methods on the trap object ... basically a trap object "base class":

BEGIN {
  my %Prop;
  my $prefix = "$^T/$$/";
  my $counter;

  sub DESTROY {
    my $self = shift;
    delete $Prop{ $self->{' id '} || '' };
  }

  sub Prop {
    my $self = shift;
    my ($package) = @_;
    $package = caller unless $package;
    $self->{' id '} = $prefix . ++$counter unless $self->{' id '};
    return $Prop{$self->{' id '}}{$package} ||= {};
  }

  sub Next { goto &{ pop @{$_[0]->Prop->{layers}} } }

  sub Teardown { my $self = shift; push @{$self->Prop->{teardown}}, @_ }

  sub Run { my $self = shift; @_ = (); goto &{$self->Prop->{code}} }

  sub TestAccessor { shift->Prop->{test_accessor} }

  sub TestFailure {
    my $self = shift;
    my $m = $self->Prop->{on_test_failure} or return;
    $self->$m(@_);
  }

  sub ExceptionFunction {
    my $self = shift;
    my $exception = $self->Prop->{exception} ||= [];
    $self->Prop->{exception_function} ||= sub {
      push @$exception, @_;
      local *@;
      eval {
        no warnings 'exiting';
        last TEST_TRAP_BUILDER_INTERNAL_EXCEPTION;
      };
      # XXX: PANIC!  We returned!?!
      CORE::exit(8); # XXX: Is there a more appropriate exit value?
    };
    return $self->Prop->{exception_function};
  }

  sub Exception {
    my $self = shift;
    $self->ExceptionFunction->(@_);
  }
}

# Utility functions and methods on the builder class/object:

sub _carpnot_for (@) {
  my %seen = ( __PACKAGE__, 1 );
  my @pkg = grep { !$seen{$_}++ } @_;
  return @pkg;
}

sub new { $builder }

sub trap {
  my $self = shift;
  my ($trapper, $glob, $layers, $code) = @_;
  my $trap = bless { wantarray => (my $wantarray = wantarray) }, $trapper;
TEST_TRAP_BUILDER_INTERNAL_EXCEPTION: {
    local *@;
    local $trap->Prop->{code} = $code;
    $trap->Prop->{layers}     = [@$layers];
    $trap->Prop->{teardown}   = [];
  TEST_TRAP_BUILDER_INTERNAL_EXCEPTION: {
      eval { $trap->Next; 1} or $trap->Exception("Rethrowing internal exception: $@");
    }
    for (reverse @{$trap->Prop->{teardown}}) {
    TEST_TRAP_BUILDER_INTERNAL_EXCEPTION: {
	eval { $_->(); 1} or $trap->Exception("Rethrowing teardown exception: $@");
      }
    }
    last if @{$trap->Prop->{exception}||[]};
    ${*$glob} = $trap;
    my @return = eval { @{$trap->return} };
    return $wantarray ? @return : $return[0];
  }
  local( GOT_CARP_NOT ? @CARP_NOT : @ISA ) = _carpnot_for $trapper, scalar caller;
  croak join"\n", @{$trap->Prop->{exception}};
}

BEGIN { # The register (private) functions:
  my %register;
  sub _register {
    my ($type, $package, $name, $val) = @_;
    $register{$type}{$package}{$name} = $val;
  }
  sub _register_packages {
    my ($type) = @_;
    return keys %{$register{$type}};
  }
  sub _register_names {
    my ($type, $package) = @_;
    return keys %{$register{$type}{$package}};
  }
  sub _register_value {
    my ($type, $package, $name) = @_;
    return $register{$type}{$package}{$name};
  }
}

BEGIN { # Test callback registration and test method generation:
  # state for the closures in %argspec -- obviously not reentrant:
  my ($accessor, $test, $index, $trap, @arg);
  my %argspec =
    ( trap      => sub { $trap },
      element   => sub { $accessor->{code}->( $trap, _need_index() ? $index = shift(@arg) : () ) },
      entirety  => sub { $accessor->{code}->( $trap ) },
      predicate => sub { shift @arg },
      name      => sub { shift @arg },
    );
  # backwards compatibility -- don't use these:
  @argspec{ qw( object all indexed ) } = @argspec{ qw( trap entirety element ) };
  # stringifying the CODE refs, that we may easily check if we have a specific one:
  my %isname    = ( $argspec{name}      => 1 );
  my %iselement = ( $argspec{element}   => 1 );
  my %takesarg  = ( $argspec{predicate} => 1 );

  sub _need_index { $accessor->{is_array} && grep $iselement{$_}, @{$test->{argspec}} }

  # a single universal test -- the leaveby test:
  # (don't worry -- the UNIVERSAL package is not actually touched)
  _register test => UNIVERSAL => did =>
    { argspec => [ $argspec{name} ],
      code    => sub { require Test::More; goto &Test::More::pass },
      pattern => '%s::did_%s',
      builder => __PACKAGE__->new,
    };

  my $basic_test = sub {
    ($accessor, $test, $trap, @arg) = @_;
    $index = '';
    my @targs = map $_->(), @{$test->{argspec}};
    my $ok;
    local $trap->Prop->{test_accessor} = "$accessor->{name}($index)";
    local $Test::Builder::Level = $Test::Builder::Level+1;

    # Work around perl5 bug #119683, as per Test-Trap bug #127112:
    my @copy = ($!, $^E);
    local ($!, $^E) = @copy;

    $ok = $test->{code}->(@targs) or $trap->TestFailure;
    $ok;
  };

  my $wrong_leaveby = sub {
    ($accessor, $test, $trap, @arg) = @_;
    require Test::More;
    my $Test = Test::More->builder;
    my $test_name_index = 0;
    for (@{$test->{argspec}}) {
      last if $isname{$_};
      $test_name_index++ if $takesarg{$_} or $accessor->{is_array} && $iselement{$_};
    }
    my $ok = $Test->ok('', $arg[$test_name_index]);
    my $got = $trap->leaveby;
    $Test->diag(sprintf<<DIAGNOSTIC, $accessor->{name}, $got, dump($trap->$got));
    Expecting to %s(), but instead %s()ed with %s
DIAGNOSTIC
    $trap->TestFailure;
    $ok;
  };

  sub _accessor_test {
    my ($apkgs, $anames, $tpkgs, $tnames) = @_;
    for my $apkg (@$apkgs ? @$apkgs : _register_packages 'accessor') {
      for my $aname (@$anames ? @$anames : _register_names accessor => $apkg) {
	my $adef = _register_value accessor => $apkg => $aname;
	for my $tpkg (@$tpkgs ? @$tpkgs : _register_packages 'test') {
	  my $mpkg = $apkg->isa($tpkg) ? $apkg
		   : $tpkg->isa($apkg) ? $tpkg
		   : next;
	  for my $tname (@$tnames ? @$tnames : _register_names test => $tpkg) {
	    my $tdef = _register_value test => $tpkg => $tname;
	    my $mname = sprintf $tdef->{pattern}, $mpkg, $aname;
	    no strict 'refs';
	    *$mname = sub {
	      my ($trap) = @_;
	      unshift @_, $adef, $tdef;
	      goto &$wrong_leaveby if $adef->{is_leaveby} and $trap->leaveby ne $adef->{name};
	      goto &$basic_test;
	    };
	  }
	}
      }
    }
  }

  sub test {
    my $self = shift;
    my ($tname, $targs, $code) = @_;
    my $tpkg = caller;
    my @targs = map { $argspec{$_} || croak "Unrecognized identifier $_ in argspec" } $targs =~ /(\w+)/g;
    _register test => $tpkg => $tname =>
      { argspec => \@targs,
	code    => $code,
	pattern => "%s::%s_$tname",
	builder => $self,
      };
    # make the test methods:
    _accessor_test( [], [], [$tpkg], [$tname] );
  }
}

BEGIN { # Accessor registration:
  my $export_accessor = sub {
    my ($apkg, $aname, $par, $code) = @_;
    no strict 'refs';
    *{"$apkg\::$aname"} = $code;
    _register accessor => $apkg => $aname =>
      { %$par,
	code => $code,
	name => $aname,
      };
    # make the test methods:
    _accessor_test( [$apkg], [$aname], [], [] );
  };

  my %accessor_factory =
    ( scalar => sub {
	my $name = shift;
	return sub { $_[0]{$name} };
      },
      array => sub {
	my $name = shift;
	return sub {
	  my $trap = shift;
	  return   $trap->{$name}      unless @_;
	  return @{$trap->{$name}}[@_] if wantarray;
	  return   $trap->{$name}[shift];
	};
      },
    );

  sub accessor {
    my $self = shift;
    my %par = @_;
    my $simple = delete $par{simple};
    my $flexible = delete $par{flexible};
    my $pkg = caller;
    for my $name (keys %{$flexible||{}}) {
      $export_accessor->($pkg, $name, \%par, $flexible->{$name});
    }
    my $factory = $accessor_factory{ $par{is_array} ? 'array' : 'scalar' };
    for my $name (@{$simple||[]}) {
      $export_accessor->($pkg, $name, \%par, $factory->($name));
    }
  }
}

BEGIN { # Layer registration:
  my $export_layer = sub {
    my ($pkg, $name, $sub) = @_;
    no strict 'refs';
    *{"$pkg\::layer:$name"} = $sub;
  };

  sub layer {
    my $self = shift;
    my ($name, $sub) = @_;
    $export_layer->(scalar caller, $name, sub { my ($self, @arg) = @_; sub { shift->$sub(@arg) } });
  }

  sub multi_layer {
    my $self = shift;
    my $name = shift;
    my $callpkg = caller;
    my @layer = $self->layer_implementation($callpkg, @_);
    $export_layer->($callpkg, $name, sub { @layer });
  }

  sub output_layer {
    my $self = shift;
    my ($name, $globref) = @_;
    my $code = sub {
      my $class = shift;
      my ($arg) = @_;
      my $strategy = $self->first_capture_strategy($arg);
      return sub {
	my $trap = shift;
	$trap->{$name} = ''; # XXX: Encapsulation violation!
	my $fileno;
	# common stuff:
	unless (tied *$globref or defined($fileno = fileno *$globref)) {
	  return $trap->Next;
	}
	my $m = $strategy; # placate Devel::Cover:
	$m = $trap->Prop->{capture_strategy} unless $m;
	$m = $self->capture_strategy('tempfile') unless $m;
	$trap->$m($name, $fileno, $globref);
      };
    };
    $export_layer->(scalar caller, $name, $code);
  }
}

BEGIN {
  my %strategy;
  # Backwards compatibility aliases; don't use:
  *output_layer_backend = \&capture_strategy;
  *first_output_layer_backend = \&first_capture_strategy;
  sub capture_strategy {
    my $this = shift;
    my ($name, $strategy) = @_;
    $strategy{$name} = $strategy if $strategy;
    return $strategy{$name};
  }
  sub first_capture_strategy {
    my $self = shift;
    my ($arg) = @_;
    return unless $arg;
    my @strategy = split /[,;]/, $arg;
    for (@strategy) {
      my $strategy = $self->capture_strategy($_);
      return $strategy if $strategy;
    }
    croak "No capture strategy found for " . dump(@strategy);
  }
}

sub layer_implementation {
  my $self = shift;
  # Directly querying layer implementation, we should know what we're doing:
  local( GOT_CARP_NOT ? @CARP_NOT : @ISA ) = _carpnot_for caller;
  my $trapper = shift;
  my @r;
  for (@_) {
    if ( length ref and eval { exists &$_ } ) {
      push @r, $_;
      next;
    }
    my ($name, $arg) =
      /^ ( [^\(]+ )      # layer name: anything but '('
         (?:             # begin optional group
             \(          # literal '('
             ( [^\)]* )  # arg: anything but ')'
             \)          # literal ')'
         )?              # end optional group
      \z/x;
    my $meth = $trapper->can("layer:$name")
      or croak qq[Unknown trap layer "$_"];
    push @r, $trapper->$meth($arg);
  }
  return @r;
}

1; # End of Test::Trap::Builder

__END__

=head1 NAME

Test::Trap::Builder - Backend for building test traps

=head1 VERSION

Version 0.3.4

=head1 SYNOPSIS

  package My::Test::Trap;

  use Test::Trap::Builder;
  my $B = Test::Trap::Builder->new;

  $B->layer( $layer_name => \&layer_implementation );
  $B->accessor( simple => [ $layer_name ] );

  $B->multi_layer( $multi_name => @names );

  $B->test( $test_name => 'trap, predicate, name', \&test_function );

=head1 DESCRIPTION

L<Test::Trap> neither traps nor tests everything you may want to trap
or test.  So, Test::Trap::Builder provides methods to write your own
trap layers, accessors, and test callbacks -- preferably for use with
your own modules (trappers).

Note that layers are methods with mangled names (names are prefixed
with C<layer:>), and so inherited like any other method, while
accessors are ordinary methods.  Meanwhile, test callbacks are not
referenced in the symbol table by themselves, but only in combinations
with accessors, all methods of the form I<ACCESSOR>_I<TEST>.

=head1 EXPORTS

Trappers should not inherit from Test::Trap::Builder, but may import a
few convenience methods for use in building the trap.  Do not use them
as methods of Test::Trap::Builder -- they are intended to be methods
of trap objects.  (If you inherit from another trapper, you need not,
and probably should not, import these yourself -- you should inherit
these methods like any other.)

Trappers may import any number of these methods, or all of them by way
of the C<:methods> tag.

Layers should be implemented as methods, and while they need not call
any of these convenience methods in turn, that likely makes for more
readable code than any alternative.  Likewise, test callbacks may use
convenience methods for more readable code.

Of course, certain convenience methods may also be useful in more
generic methods messing with trap or builder objects.

=head2 Prop [PACKAGE]

A method returning a reference to a hash, holding the I<PACKAGE>'s (by
default the caller's) tag-on properties for the (current) trap object.
Currently, Test::Trap::Builder defines the following properties:

=over

=item layers

While the trap is springing, the queue of layers remaining.  Usually
set by the L</"trap"> method and consumed by the L</"Next"> method.

=item teardown

While the trap is springing, the queue of teardown actions remaining.
Usually accumulated through the L</"Teardown"> method and invoked by
the L</"trap"> method.

=item code

The user code trapped.  Usually set by the L</"trap"> method and
invoked by the L</"Run"> method.

=item exception

An internal exception.  Usually set through the L</"Exception">
method and examined by the L</"trap"> method.

=item on_test_failure

A callback invoked by the L</"TestFailure"> method.  Layers in
particular may want to set this.

=item test_accessor

The name and (optionally) the index of the accessor, the contents of
which we're currently testing.  Best accessed through the
L</"TestAccessor"> method, and usually set by the L</"test"> and
L</"accessor"> methods, but if you are writing your own tests or
accessors directly, you just might need to set it.  Perhaps.

=back

Be nice: Treat another module's tag-on properties as you would treat
another module's global variables.  Don't use them except as
documented.

Example:

  # in a layer, setting the callback for TestFailure:
  $self->Prop('Test::Trap::Builder')->{on_test_failure} = \&mydiag;

=head2 DESTROY

This cleans up the tag-on properties when the trap object is
destroyed.  Don't try to make a trapper that doesn't call this; it
will get confused.

If your trapper needs its own C<DESTROY>, make sure it calls this one
as well:

  sub DESTROY {
    my $self = shift;
    # do your thing
    $self->Test::Trap::Builder::DESTROY;
    # and more things
  }

=head2 Run

A terminating layer should call this method to run the user code.
Should only be called in a dynamic context in which layers are being
applied.

=head2 Next

Every non-terminating layer should call this method (or an equivalent)
to progress to the next layer.  Should only be called in a dynamic
context in which layers are being applied.  Note that this method need
not return, so any tear-down actions should probably be registered with
the Teardown method (see below).

=head2 Teardown SUBS

If your layer wants to clean up its setup, it may use this method to
register any number of tear-down actions, to be performed (in reverse
registration order) once the user code has been executed.  Should only
be called in a dynamic context in which layers are being applied.

=head2 TestAccessor

Returns a string of the form C<"I<NAME>(I<INDEX>)">, where I<NAME> and
I<INDEX> are the name of the accessor and the index (if any) being
tested.  Should only be called in the dynamic context of test
callbacks.

This is intended for diagnostics:

  diag( sprintf 'Expected %s in %s; got %s',
	$expected, $self->TestAccessor, dump($got),
      );

=head2 TestFailure

Runs the C<on_test_failure> tag-on property (if any) on the trap
object.  If you are writing unregistered tests, you might want to
include (some variation of) this call:

  $ok or $self->TestFailure;

=head2 Exception STRINGS

Layer implementations may run into exceptional situations, in which
they want the entire trap to fail.  Unfortunately, another layer may
be trapping ordinary exceptions, so you need some kind of magic in
order to throw an untrappable exception.  This is one convenient way.

Should only be called in a dynamic context in which layers are being
applied.

Note: The Exception method won't work if called from outside of the
regular control flow, like inside a DESTROY method or signal handler.
If anything like this happens, CORE::exit will be called with an exit
code of 8.

Note: Direct calls to the Exception method within closures may cause
circular references and so leakage.  To avoid this, fetch an
L</"ExceptionFunction"> and call it from the closure instead.

=head2 ExceptionFunction

This method returns a function that may be called with the same effect
as calling the L</"Exception"> method, allowing closures to throw
exceptions without causing circular references by closing over the
trap object itself.

To illustrate:

  # this will create a circular reference chain:
  # trap object has property collection has teardown closure has trap object
  $self->Teardown($_) for sub {
    do_stuff() or $self->Exception("Stuff didn't work.");
  };

  # this will break the circular reference chain:
  # teardown closure no longer has trap object
  $Exception = $self->ExceptionFunction;
  $self->Teardown($_) for sub {
    do_things() or $Exception->("Things didn't work.");
  };

=head1 METHODS

=head2 new

Returns a singleton object.  Don't expect this module to work with a
different instance object of this class.

=head2 trap TRAPPER, GLOBREF, LAYERARRAYREF, CODE

Implements a trap for the I<TRAPPER> module, applying the layers of
I<LAYERARRAYREF>, trapping various outcomes of the user I<CODE>, and
storing the trap object into the scalar slot of I<GLOBREF>.

In most cases, the trapper should conveniently export a function
calling this method.

=head2 layer NAME, CODE

Registers a layer by I<NAME> to the calling trapper.  When the layer
is applied, the I<CODE> will be invoked on the trap object being
built, with no arguments, and should call either the Next() or Run()
method or equivalent.

=head2 output_layer NAME, GLOBREF

Registers (by I<NAME> and to the calling trapper) a layer for trapping
output on the file handle of the I<GLOBREF>, using I<NAME> also as the
attribute name.

=head2 capture_strategy NAME, [CODE]

When called with two arguments, registers (by I<NAME> and globally) a
strategy for output trap layers.  When called with a single argument,
looks up and returns the strategy registered by I<NAME> (or undef).

When a layer using this strategy is applied, the I<CODE> will be called
on the trap object, with the layer name and the output handle's fileno
and globref as arguments.

=head2 output_layer_backend SPEC

Back-compat alias of the above.

=head2 first_capture_strategy SPEC

Where I<SPEC> is empty, just returns.

Where I<SPEC> is a string of comma-or-semicolon separated names, runs
through the names, returning the first strategy it finds.  Dies if no
strategy is found by any of these names.

=head2 first_output_layer_backend SPEC

Back-compat alias of the above.

=head2 multi_layer NAME, LAYERS

Registers (by I<NAME>) a layer that just pushes a number of other
I<LAYERS> on the stack of layers.  If any of the I<LAYERS> is neither
an anonymous method nor the name of a layer registered to the caller
or a trapper it inherits from, an exception is raised.

=head2 layer_implementation TRAPPER, LAYERS

Returns the subroutines that implement the requested I<LAYERS>.  If
any of the I<LAYERS> is neither an anonymous method nor the name of a
layer registered to or inherited by the I<TRAPPER>, an exception is
raised.

=head2 accessor NAMED_ARGS

Generates and registers any number of accessors according to the
I<NAMED_ARGS>, and also generates the proper test methods for these
accessors (see below).

The following named arguments are recognized:

=over

=item is_leaveby

If true, the tests methods will generate better diagnostics if the
trap was not left as specified.  Also, a special did_I<ACCESSOR> test
method will be generated (unless already present), simply passing as
long as the trap was left as specified.

=item is_array

If true, the simple accessor(s) will be smart about context and
arguments, returning an arrayref on no argument (in any context), an
array slice in list context (on any number of arguments), and the
element indexed by the first argument otherwise.

=item simple

Should be a reference to an array of accessor names.  For each name,
an accessor (assuming hash based trap object with accessor names as
keys), will be generated and registered.

=item flexible

Should be a reference to a hash.  For each pair, a name and an
implementation, an accessor is generated and registered.

=back

=head2 test NAME, ARGSPEC, CODE

Registers a test callback by I<NAME> and to the calling trapper.

Trappers inherit test callbacks like methods (though they are not
implemented as such; don't expect to find them in the symbol table).

Test methods of the form I<ACCESSOR>_I<TEST> will be made available
(directly or by inheritance) to every trapper that registers or
inherits both the accessor named I<ACCESSOR> and the test named
I<TEST>.

(In more detail, the method will be generated in every trapper that
either (1) registers both the test and the accessor, or (2) registers
either and inherits the other.)

When the test method is called, any implicit leaveby condition will be
tested first, and if it passes (or there were none), the I<CODE> is
called with arguments according to the words found in the I<ARGSPEC>
string:

=over

=item trap

The trap object.

=item entirety

The I<ACCESSOR>'s return value when called without arguments.

=item element

The I<ACCESSOR>'s return value when called with index, if applicable
(i.e. for array accessors).  Index is not applicable to scalar
accessors, so such are still called without index.

The index, when applicable, will be taken from the test method's
arguments.

=item predicate

What the I<ACCESSOR>'s return value should be tested against (taken
from the test method's arguments).  (There may be any fixed number of
predicates.)

=item name

The test name (taken from the test method's arguments).

=back

=head1 EXAMPLE

A complete example, implementing a I<timeout> layer (depending on
Time::HiRes::ualarm being present), a I<simpletee> layer (printing the
trapped stdout/stderr to the original file handles after the trap has
sprung), and a I<cmp_ok> test method template:

  package My::Test::Trap;
  use base 'Test::Trap'; # for example
  use Test::Trap::Builder;

  my $B = Test::Trap::Builder->new;

  # example (layer:timeout):
  use Time::HiRes qw/ualarm/;
  $B->layer( timeout => $_ ) for sub {
    my $self = shift;
    eval {
      local $SIG{ALRM} = sub {
	$self->{timeout} = 1; # simple truth
	$SIG{ALRM} = sub {die};
	die;
      };
      ualarm 1000, 1; # one second max, then die repeatedly!
      $self->Next;
    };
    alarm 0;
    if ($self->{timeout}) {
      $self->{leaveby} = 'timeout';
      delete $self->{$_} for qw/ die exit return /;
    }
  };
  $B->accessor( is_leaveby => 1,
		simple => ['timeout'],
	      );

  # example (layer:simpletee):
  $B->layer( simpletee => $_ ) for sub {
    my $self = shift;
    for (qw/ stdout stderr /) {
      exists $self->{$_} or $self->Exception("Too late to tee $_");
    }
    $self->Teardown($_) for sub {
      print STDOUT $self->{stdout} if exists $self->{stdout};
      print STDERR $self->{stderr} if exists $self->{stderr};
    };
    $self->Next;
  };
  # no accessor for this layer

  $B->multi_layer( flow => qw/ raw die exit timeout / );
  $B->multi_layer( default => qw/ flow stdout stderr warn simpletee / );

  $B->test_method( cmp_ok => 1, 2, \&Test::More::cmp_ok );

=head1 CAVEATS

The interface of this module is likely to remain somewhat in flux for
a while yet.

The different strategies for output trap layers have their own
caveats; see L<Test::Trap::Builder::Tempfile>,
L<Test::Trap::Builder::PerlIO>, L<Test::Trap::Builder::SystemSafe>.

Multiple inheritance is not (yet?) fully supported.  If one parent has
registered a test callback C<X> and another has registered an accessor
C<Y>, the test method C<Y_X> will not be generated.

Threads?  No idea.  It might even work correctly.

=head1 BUGS

Please report any bugs or feature requests directly to the author.

=head1 AUTHOR

Eirik Berg Hanssen, C<< <ebhanssen@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2014 Eirik Berg Hanssen, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
