package Test::Trap;

use version; $VERSION = qv('0.3.4');

use strict;
use warnings;
use Carp qw( croak );
use Data::Dump qw(dump);
use Test::Trap::Builder qw( :methods );

my $B = Test::Trap::Builder->new;

sub import {
  my $trapper = shift;
  my $callpkg = caller;
  my (@function, @scalar, @layer);
  while (@_) {
    my $sym = shift;
    UNIVERSAL::isa($sym, 'CODE') ? push @layer,    $sym :
    $sym =~ s/^://               ? push @layer,    split/:/, $sym :
    $sym =~ s/^\$//              ? push @scalar,   $sym :
    $sym !~ m/^[@%*]/            ? push @function, $sym :
    croak qq["$sym" is not exported by the $trapper module];
  }
  if (@function > 1) {
    croak qq[The $trapper module does not export more than one function];
  }
  if (@scalar > 1) {
    croak qq[The $trapper module does not export more than one scalar];
  }
  my $function = @function ? $function[0] : 'trap';
  my $scalar = @scalar ? $scalar[0] : 'trap';
  @layer = $B->layer_implementation($trapper, default => @layer);
  no strict 'refs';
  my $gref = \*{"$callpkg\::$scalar"};
  *$gref = \ do { my $x = bless {}, $trapper };
  *{"$callpkg\::$function"} = sub (&) {
    $B->trap($trapper, $gref, \@layer, shift);
  }
}

####################
#  Standard layers #
####################

# The big one: trapping exits correctly:
EXIT_LAYER: {
  # A versatile &CORE::GLOBAL::exit candidate:
  sub _global_exit (;$) {
    my $exit = @_ ? 0+shift : 0;
    ___exit($exit) if exists &___exit;
    CORE::exit($exit);
  };

  # Need to have &CORE::GLOBAL::exit set, one way or the other,
  # before any code to be trapped is compiled:
  *CORE::GLOBAL::exit = \&_global_exit unless exists &CORE::GLOBAL::exit;

  # And at last, the layer for exits:
  $B->layer(exit => $_) for sub {
    my $self = shift;
    # in case someone else is messing with exit:
    my $pid = $$;
    my $outer = \&CORE::GLOBAL::exit;
    undef $outer if $outer == \&_global_exit;
    local *___exit;
  TEST_TRAP_EXITING: {
      {
	no warnings 'redefine';
	*___exit = sub {
	  if ($$ != $pid) {
	    return $outer->(@_) if $outer;
	    # XXX: This is fuzzy ... how to test this right?
	    CORE::exit(shift);
	  }
	  $self->{exit} = shift;
	  $self->{leaveby} = 'exit';
	  no warnings 'exiting';
	  last TEST_TRAP_EXITING;
	};
      }
      local *CORE::GLOBAL::exit;
      *CORE::GLOBAL::exit = \&_global_exit;
      $self->Next;
    }
    return;
  };
}

# The other layers and standard accessors:

# Note: :raw is a terminating layer -- it does not call any lower
# layer, but is the layer responsible for calling the actual code!
$B->layer(raw => $_) for sub {
  my $self = shift;
  my $wantarray = $self->{wantarray};
  my @return;
  unless (defined $wantarray) { $self->Run }
  elsif ($wantarray) { @return = $self->Run }
  else { @return = scalar $self->Run }
  $self->{return} = \@return;
  $self->{leaveby} = 'return';
};

# A simple layer for exceptions:
$B->layer(die => $_) for sub {
  my $self = shift;
  local *@;
  return if eval { $self->Next; 1 };
  $self->{die} = $@;
  $self->{leaveby} = 'die';
};

# Layers for STDOUT and STDERR, from the factory:
$B->output_layer( stdout => \*STDOUT );
$B->output_layer( stderr => \*STDERR );
BEGIN {
  # Make available some capture strategies:
  use Test::Trap::Builder::TempFile;
  use Test::Trap::Builder::TempFile 'tempfile-preserve' => { preserve_io_layers => 1 };
  # optional capture strategies:
  eval q{ use Test::Trap::Builder::PerlIO };
  eval q{ use Test::Trap::Builder::SystemSafe };
  eval q{ use Test::Trap::Builder::SystemSafe 'systemsafe-preserve' => { preserve_io_layers => 1 } };
}

# A simple layer for warnings:
$B->layer(warn => $_) for sub {
  my $self = shift;
  my @warn;
  # Can't local($SIG{__WARN__}) because of a perl bug with local() on
  # scalar values under the Windows fork() emulation -- work around:
  my $sigwarn = $SIG{__WARN__};
  my $sigwarn_exists = exists $SIG{__WARN__};
  $SIG{__WARN__} = sub {
    my $w = shift;
    push @warn, $w;
    print STDERR $w if defined fileno STDERR;
  };
  $self->Teardown($_) for sub {
    if ($sigwarn_exists) {
      $SIG{__WARN__} = $sigwarn;
    }
    else {
      delete $SIG{__WARN__};
    }
  };
  $self->{warn} = \@warn;
  $self->Next;
};

# Multi-layers:
$B->multi_layer(flow => qw/ raw die exit /);
$B->multi_layer(default => qw/ flow stdout stderr warn /);

# Non-default non-trapping layers:
$B->layer( void => $_ ) for sub {
  my $self = shift;
  undef $self->{wantarray};
  $self->Next;
};
$B->layer( scalar => $_ ) for sub {
  my $self = shift;
  $self->{wantarray} = '';
  $self->Next;
};
$B->layer( list => $_ ) for sub {
  my $self = shift;
  $self->{wantarray} = 1;
  $self->Next;
};
$B->layer( on_fail => $_ ) for sub {
  my $self = shift;
  my ($arg) = @_;
  $self->Prop('Test::Trap::Builder')->{on_test_failure} = $arg;
  $self->Next;
};
$B->layer( output => $_ ) for sub {
  my $self = shift;
  my $strategy = eval { $B->first_capture_strategy(@_) };
  $self->Exception($@) if $@;
  $self->Prop('Test::Trap::Builder')->{capture_strategy} = $strategy;
  $self->Next;
};

########################
#  Standard accessors  #
########################

$B->accessor( simple => [ qw/ leaveby stdout stderr wantarray / ],
	      flexible =>
	      { list => sub {
		  $_[0]{wantarray};
		},
		scalar => sub {
		  my $x = $_[0]{wantarray};
		  !$x and defined $x;
		},
		void => sub {
		  not defined $_[0]{wantarray};
		},
	      },
	    );
$B->accessor( is_leaveby => 1,
	      simple => [ qw/ exit die / ],
	    );
$B->accessor( is_array => 1,
	      simple => [ qw/ warn / ],
	    );
$B->accessor( is_array => 1,
	      is_leaveby => 1,
	      simple => [ qw/ return / ],
	    );

####################
#  Standard tests  #
####################

# This helper and similar strategies below delay loading Test::More
# until we actually use this stuff, so that It Just Works if we:
#     0) have already loaded and planned with Test::More ;-)
#     1) have already loaded and planned with some other Test::Builder module
#     2) aren't actually testing, just trapping
sub _test_more($) {
  my $sym = shift;
  sub {
    require Test::More;
    goto &{"Test::More::$sym"};
  };
}

for my $simple (qw/ is isnt like unlike isa_ok /) {
  $B->test( $simple => 'element, predicate, name', _test_more $simple );
}

$B->test( is_deeply => 'entirety, predicate, name', _test_more 'is_deeply' );

$B->test( ok => 'trap, element, name', $_ ) for sub {
  my $self = shift;
  my ($got, $name) = @_;
  require Test::More;
  my $Test = Test::More->builder;
  my $ok = $Test->ok( $got, $name );
  $Test->diag(sprintf<<OK, $self->TestAccessor, dump($got)) unless $ok;
    Expecting true value in %s, but got %s instead
OK
  return $ok;
};

$B->test( nok => 'trap, element, name', $_ ) for sub {
  my $self = shift;
  my ($got, $name) = @_;
  require Test::More;
  my $Test = Test::More->builder;
  my $ok = $Test->ok( !$got, $name );
  $Test->diag(sprintf<<NOK, $self->TestAccessor, dump($got)) unless $ok;
    Expecting false value in %s, but got %s instead
NOK
  return $ok;
};

# Extra convenience test method:
sub quiet {
  my $self = shift;
  my ($name) = @_;
  my @fail;
  for my $m (qw/stdout stderr/) {
    my $buf = $self->$m . ''; # coerce to string
    push @fail, "Expecting no \U$m\E, but got " . dump($buf) if $buf ne '';
  }
  require Test::More;
  my $Test = Test::More->builder;
  my $ok = $Test->ok(!@fail, $name) or do {
    $Test->diag(join"\n", @fail);
    $self->TestFailure;
  };
  $ok;
}

#####################
#  Utility methods  #
#####################

sub diag_all {
  my $self = shift;
  require Test::More;
  Test::More::diag( dump $self );
}

sub diag_all_once {
  my $self = shift;
  my $msg = $self->Prop->{diag_all_once}++ ? '(as above)' : dump $self;
  require Test::More;
  Test::More::diag( $msg );
}

1; # End of Test::Trap

__END__

=head1 NAME

Test::Trap - Trap exit codes, exceptions, output, etc.

=head1 VERSION

Version 0.3.4

=head1 SYNOPSIS

  use Test::More;
  use Test::Trap;

  my @r = trap { some_code(@some_parameters) };
  is ( $trap->exit, 1, 'Expecting &some_code to exit with 1' );
  is ( $trap->stdout, '', 'Expecting no STDOUT' );
  like ( $trap->stderr, qr/^Bad parameters; exiting\b/, 'Expecting warnings.' );

=head1 DESCRIPTION

Primarily (but not exclusively) for use in test scripts: A block eval
on steroids, configurable and extensible, but by default trapping
(Perl) STDOUT, STDERR, warnings, exceptions, would-be exit codes, and
return values from boxed blocks of test code.

The values collected by the latest trap can then be queried or tested
through a special trap object.

=head1 EXPORT

A function and a scalar may be exported by any name.  The function (by
default named C<trap>) is an analogue to block eval(), and the scalar
(by default named C<$trap>) is the corresponding analogue to C<$@>.

Optionally, you may specify the layers of the exported trap.  Layers
may be specified by name, with a colon sigil.  Multiple layers may be
given in a list, or just stringed together like C<:flow:stderr:warn>.

(For the advanced user, you may also specify anonymous layer
implementations -- i.e. an appropriate subroutine.)

See below for a list of the built-in layers, most of which are enabled
by default.  Note, finally, that the ordering of the layers matter:
The :raw layer is always on the bottom (anything underneath it is
ignored), and any other "flow control" layers used should be right
down there with it.

=head1 FUNCTION

=head2 trap BLOCK

This function may be exported by any name, but defaults to C<trap>.

By default, traps exceptions (like block eval), but also exits and
exit codes, returns and return values, context, and (Perl) output on
STDOUT or STDERR, and warnings.  All information trapped can be
queried through the trap object, which is by default exported as
C<$trap>, but can be exported by any name.

The value returned from C<trap> mimics that returned from C<eval>:  If
the I<BLOCK> would die or exit, it returns an undefined value in
scalar context or an empty list in list context; otherwise it returns
whatever the I<BLOCK> would return in the given context (also
available as the trapped return values).

=head1 TRAP LAYERS

Exactly what the C<trap> traps depends on the layers of the trap.  It
is possible to register more (see L<Test::Trap::Builder>), but the
following layers are pre-defined by this module:

=head2 :raw

The only built-in terminating layer, at which the processing of the
layers stops, and the actual call to the user code is performed.  On
success, it collects the return value(s) in the appropriate context.
Pushing the :raw layer on a trap will for most purposes remove all
layers below.

=head2 :die

The layer emulating block eval, trapping normal exceptions.

=head2 :exit

The third "flow control" layer, capturing exit codes if anything used
in the dynamic scope of the trap calls CORE::GLOBAL::exit().  (See
CAVEATS below for more.)

=head2 :flow

A shortcut for :raw:die:exit (effectively pushing all three layers on
the trap).  Since this includes :raw, it is also terminating:  Pushing
:flow on a trap will effectively remove all layers below.

=head2 :stdout, :stderr

Layers trapping Perl output on STDOUT and STDERR, respectively.

=head2 :stdout(perlio), :stderr(perlio)

As above, but specifying a capture strategy using PerlIO::scalar.  If
this strategy is not available (typically if PerlIO is not), this is
an error.  See L</"CAPTURE STRATEGIES">.

=head2 :stdout(tempfile), :stderr(tempfile)

As above, but specifying a capture strategy using File::Temp.  Note
that this is the default strategy, unless the C<:output()> layer is
used to set another default.  See L</"CAPTURE STRATEGIES">.

=head2 :stdout(a;b;c), :stderr(a,b,c)

(Either syntax, commas or semicolons, is permitted, as is any number
of names in the list.)  As above, but specifying the capture strategy
by the first existing name among I<a>, I<b>, and I<c>.  If no such
strategy is found, this is an error.  See L</"CAPTURE STRATEGIES">.

=head2 :warn

A layer trapping warnings, with additional tee: If STDERR is open, it
will also print the warnings there.  (This output may be trapped by
the :stderr layer, be it above or below the :warn layer.)

=head2 :default

A short-cut for :raw:die:exit:stdout:stderr:warn (effectively pushing
all six layers on the trap).  Since this includes :raw, it is also
terminating:  Pushing :default on a trap will effectively remove all
layers below.

The other interesting property of :default is that it is what every
trap starts with:  In order not to include the six layers that make up
:default, you need to push a terminating layer (such as :raw or :flow)
on the trap.

=head2 :on_fail(m)

A (non-default, non-trapping) layer that installs a callback method
(by name) I<m> to be run on test failures.  To run the L</"diag_all">
method every time a test fails:

  use Test::Trap qw/ :on_fail(diag_all) /;

=head2 :void, :scalar, :list

These (non-default, non-trapping) layers will cause the trapped user
code to be run in void, scalar, or list context, respectively.  (By
default, the trap will propagate context, that is, it will run the
code in whatever context the trap itself is in.)

If more than one of these layers are pushed on the trap, the deepest
(that is, leftmost) takes precedence:

  use Test::Trap qw/ :scalar:void:list /;
  trap { 42, 13 };
  $trap->return_is_deeply( [ 13 ], 'Scalar comma.' );

=head2 :output(a;b;c)

A (non-default, non-trapping) layer that sets the default capture
strategy for any output trapping (C<:stdout>, C<:stderr>, or other
similarly defined) layers below iton the trap.

  use Test::Trap qw/ :output(systemsafe) /;
  trap { system echo => 'Hello Unix!' }; # trapped!

  use Test::Trap qw/ :flow:stderr:output(systemsafe):stdout /;
  trap { system echo => 'Hello Unix!' }; # *not* trapped!
  trap { system q/ echo 'Hello Unix!' >&2 / }; # trapped!

See L</"CAPTURE STRATEGIES">.

=head1 CAPTURE STRATEGIES

How output is trapped, depends on the capture strategy used.  It is
possible to register more (see L<Test::Trap::Builder>), but the
following strategies are pre-defined by this module:

=head2 tempfile

The default capture strategy, provided by
L<Test::Trap::Builder::TempFile>, in which output is temporarily
redirected to (and read back from) a tempfile.

=head2 tempfile-preserve

A variant of the capture strategy provided by
L<Test::Trap::Builder::TempFile>, in which the handles used to write
to and read from the tempfile are both binmoded with the same perlio
layers as the trapped output handle originally had.

Caveat emptor: If the handle has perlio custom layers, they may (or
may not) fail to apply to the tempfile read and write handles.

=head2 systemsafe

A capture strategy provided by L<Test::Trap::Builder::SystemSafe>,
like the default strategy, except it outputs on file handles with the
same file descriptors as the trapped output handle originally had, and
so can be used to trap output from forked-off processes, including
system().

This strategy may be "safe" in relation to forked-off processes, but
it is fragile.  For one, it only works with handles that have "real"
file descriptors.  For another, it depends on the original file
descriptors being available after closing.  (If signal handlers or
threads open files, they may well not be.)  And it may fail in other
ways.  But in relation to forked-off processes, the other pre-defined
strategies will silently fail to trap, as will similarly simple
strategies.  This one, when not crashing, will trap that output.

=head2 systemsafe-preserve

A variant of the capture strategy provided by
L<Test::Trap::Builder::SystemSafe>, in which the handles used to write
to and read from the tempfile are both binmoded with the same perlio
layers as the trapped output handle originally had.

Caveat emptor: If the handle has perlio custom layers, they may (or
may not) fail to apply to the tempfile read and write handles.

=head2 perlio

A capture strategy provided by L<Test::Trap::Builder::PerlIO>, in
which output is temporarily redirected to an in-memory file via
PerlIO::scalar.

If PerlIO::scalar is not available, neither is this strategy.

=head1 RESULT ACCESSORS

The following methods may be called on the trap objects after any trap
has been sprung, and access the outcome of the run.

Any property will be undef if not actually trapped -- whether because
there is no layer to trap them or because flow control passed them by.
(If there is an active and successful trap layer, empty strings and
empty arrays trapped will of course be defined.)

When properties are set, their values will be as follows:

=head2 leaveby

A string indicating how the trap terminated: C<return>, C<die>, or
C<exit>.

=head2 die

The exception, if the latest trap threw one.

=head2 exit

The exit code, if the latest trap tried to exit (by way of the trap's
own &CORE::GLOBAL::exit only; see L</"CAVEATS">).

=head2 return [INDEX ...]

Returns undef if the latest trap did not terminate with a return;
otherwise returns three different views of the return array:

=over

=item

if no I<INDEX> is passed, returns a reference to the array (NB! an
empty array of indices qualifies as "no index")

=item

if called with at least one I<INDEX> in scalar context, returns the
array element indexed by the first I<INDEX> (ignoring the rest)

=item

if called with at least one I<INDEX> in list context, returns the
slice of the array by these indices

=back

Note: The array will hold but a single value if the trap was sprung in
scalar context, and will be empty if it was in void context.

=head2 stdout, stderr

The captured output on the respective file handles.

=head2 warn [INDEX]

Returns undef if the latest trap had no warning-trapping layer;
otherwise returns three different views of the warn array:

=over

=item

if no I<INDEX> is passed, returns a reference to the array (NB! an
empty array of indices qualifies as "no index")

=item

if called with at least one I<INDEX> in scalar context, returns the
array element indexed by the first I<INDEX> (ignoring the rest)

=item

if called with at least one I<INDEX> in list context, returns the
slice of the array by these indices

=back

=head2 wantarray

The context in which the latest code trapped was called.  (By default
a propagated context, but layers can override this.)

=head2 list, scalar, void

True if the latest code trapped was called in the indicated context.
(By default the code will be called in a propagated context, but
layers can override this.)

=head1 RESULT TESTS

For each accessor, a number of convenient standard test methods are
also available.  By default, these are a few standard tests from
Test::More, plus the C<nok> test (a negated C<ok> test).  All for
convenience:

=head2 I<ACCESSOR>_ok        [INDEX,] TEST_NAME

=head2 I<ACCESSOR>_nok       [INDEX,] TEST_NAME

=head2 I<ACCESSOR>_is        [INDEX,] SCALAR, TEST_NAME

=head2 I<ACCESSOR>_isnt      [INDEX,] SCALAR, TEST_NAME

=head2 I<ACCESSOR>_isa_ok    [INDEX,] SCALAR, INVOCANT_NAME

=head2 I<ACCESSOR>_like      [INDEX,] REGEX, TEST_NAME

=head2 I<ACCESSOR>_unlike    [INDEX,] REGEX, TEST_NAME

=head2 I<ACCESSOR>_is_deeply          STRUCTURE, TEST_NAME

I<INDEX> is not optional:  It is required for array accessors (like
C<return> and C<warn>), and disallowed for scalar accessors.  Note
that the C<is_deeply> test does not accept an index.  Even for array
accessors, it operates on the entire array.

For convenience and clarity, tests against a flow control I<ACCESSOR>
(C<return>, C<die>, C<exit>, or any you define yourself) will first
test whether the trap was left by way of the flow control mechanism in
question, and fail with appropriate diagnostics otherwise.

=head2 did_die, did_exit, did_return

Conveniences: Tests whether the trap was left by way of the flow
control mechanism in question.  Much like C<leaveby_is('die')> etc,
but with better diagnostics and (run-time) spell checking.

=head2 quiet

Convenience: Passes if zero-length output was trapped on both STDOUT
and STDERR, and generate better diagnostics otherwise.

=head1 UTILITIES

=head2 diag_all

Prints a diagnostic message (as per L<Test::More/"diag">) consisting
of a dump (in Perl code, as per L<Data::Dump>) of the trap object.

=head2 diag_all_once

As L</"diag_all">, except if this instance of the trap object has
already been diag_all_once'd, the diagnostic message will instead
consist of the string C<(as above)>.

This could be useful with the C<on_fail> layer:

  use Test::Trap qw/ :on_fail(diag_all_once) /;

=head1 CAVEATS

This module must be loaded before any code containing exit()s to be
trapped is compiled.  Any exit() already compiled won't be trappable,
and will terminate the program anyway.

This module overrides &CORE::GLOBAL::exit, so may not work correctly
(or even at all) in the presence of other code overriding
&CORE::GLOBAL::exit.  More precisely: This module installs its own
exit() on entry of the block, and restores the previous one, if any,
only upon leaving the block.

If you use fork() in the dynamic scope of a trap, beware that the
(default) :exit layer of that trap does not trap exit() in the
children, but passes them to the outer handler.  If you think about
it, this is what you are likely to want it to do in most cases.

Note that the (default) :exit layer only traps &CORE::GLOBAL::exit
calls (and bare exit() calls that compile to that).  It makes no
attempt to trap CORE::exit(), POSIX::_exit(), exec(), untrapped
exceptions from die(), nor segfault.  Nor does it attempt to trap
anything else that might terminate the program.  The trap is a block
eval on steroids -- not the last block eval of Krypton!

This module traps warnings using C<$SIG{__WARN__}>, so may not work
correctly (or even at all) in the presence of other code setting this
handler.  More precisely: This module installs its own __WARN__
handler on entry of the block, and restores the previous one, if any,
only upon leaving the block.

The (default) :stdout and :stderr handlers will not trap output from
system() calls.

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
