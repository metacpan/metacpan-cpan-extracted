package Tie::Constrained;

=head1 NAME

Tie::Constrained - Auto pre-validation of changes to variables

=cut


use Exporter;
use Carp;

use vars qw/
    $VERSION
    $VERBOSE
    $STRICT
    @ISA
    @EXPORT
    @EXPORT_OK
    %EXPORT_TAGS
/;

BEGIN { @ISA = qw/Exporter/; }

use Errno qw/
    EINVAL
    EDOM
    ERANGE
/;

$VERSION = '0.03';
sub VERSION () {$VERSION}

$STRICT = 0;

=head1 SYNOPSIS

Following the usual convention for optional arguments,

  use Tie::Constrained
      [qw/[:all] [:dummy] [:diagnostic] [:error] [subname ...]/];

Tie::Constrained aggregates a tied scalar variable with a validation test and a failure handler. The general syntax for the tie is:

  [$var_ctl =] tie $var, 'Tie::Constrained'[,
        [ \&validator [, $initval [, \&fail_handler]]]
      | [ $hashref ]
      | [ $TC_obj ]];

A constructor is available for unbound Tie::Constraint objects

  my $TC_obj = Tie::Constrained->new (
        [ \&validator [, $initval [, \&fail_handler]]]
      | [ $hashref ]
      | [ $TC_obj ] );

There is a concise wrapper for the tie,

  [$var_ctl =] constrain( $var,
        [ \&validator [, $initval [, \&fail_handler]]]
      | [ $hashref ]
      | [ $TC_obj ] );

Validity tests should expect a single argument, the proposed new value for the tied variable. They should return true if the value is to be accepted, false if the failure handler is to be called. The passed value is modifiable.

Failure handlers should expect three arguments -- a reference to the validator which failed, the value it failed with, and an error number which is assigned to $!. If they return at all, they should return false if the value is to be rejected, true if it is now to be accepted. The passed value is modifiable.

=cut

@EXPORT = ();

@EXPORT_OK = qw/
    EINVAL
    EDOM
    ERANGE
    notest
    deny
    death
    warning
    ignore
    allow
    eraser
    constrain
    detaint
/;

%EXPORT_TAGS = (
    diagnostic => [qw/death warnings/],
    dummy      => [qw/notest deny ignore allow/],
    all        => [@EXPORT_OK],
    error      => [qw/EINVAL EDOM ERANGE/],
);

=head1 DESCRIPTION

C<Tie::Constrained> is a simple tie class for constraining the values a variable tied to it may take. The commonest use for that is to validate data. The tied interface provides the unique ability to wedge the validation test into assignment and mutator operations, prior to changing the variable's value. The effect is to ensure that the tied variable is I<always> validated by the associated test.

In the tie statement,

  $foo_ctl = tie $foo, 'Tie::Constrained',
      \&validator, $initval, \&fail_handler;

The C<validator> function should be designed to return true on success, false otherwise. It should expect the value to be tested as its first argument.
If C<$initval> is given, it will be tested by C<validator($initval)> before the value is committed.
The C<fail_handler()> is the action to be taken when C<validator()> returns false. If the failure handler returns, its value should be true if the proposed new value is to be accepted, false if it is to be ignored. Fail handlers are called with three arguments. The first is a coderef to the test which failed. The second is the value it tested. The third is an error number which is assigned to $! in the handler.
User tests and handlers may make whatever use thay wish of the arguments, but $! should be set to the third argument. Value arguments are modifiable through their alias in C<@_>, allowing tests and handlers to modify them before committal. That capability should be treated with respect, it is prone to high obfuscation.
Avoid setting C<$var_ctl> unless you really need to modify the tie on the fly. Testing the return value for logical truth is sufficient to check for success of the tie. 
Since a C<Tie::Constrained> object may be used as an initializer in the C<tie> call, it is convenient to be able to produce them independent of any binding. That is provided by the C<new> class method.
 
=head2 Philosophy

C<Tie::Constrained> is a low level module, and most of the interface is designed to remind the user of that fact. That design choice is deliberate. It is also designed to be relentlessly Object Oriented, though not in the way that equates library files and modules and classes and types.
The C<tie> mechanism constructs an object instance which, to the user, is simply a variable. The interface to the object is all the universe of perl operators and functions which may be applied to that variable. The underlying object aggregates the value of the variable, a validity test, and a handler for failure of the test. That is the C<Tie::Constrained> object proper.
The C<STORE> and C<FETCH> methods of the C<Tie::Constrained> object are sufficient to hook into every use of the tied variable by perl. That allows us to place our own conditions on what uses we will accept. Perl itself does all the rest of the work. To restrict assignment or a mutator operator, we don't need to overload the operators or write code around each use of them. Our tied wedge into perl is sufficient to make it all happen automatically.

To use C<Tie::Constrained> effectively, you should understand how it works. That is the subject of the next section,

=head2 TieGuts

The C<STORE()> method of a tied class is called when perl has a value to be stored in the tied variable. C<STORE()> must take care of storing the value where the tied object expects it, and must return a value which perl sees as the value of the operation. That value may be passed along in chained assignments or returned from a sub, among other possibilities.

C<&Tie::Constrained::STORE> does not automatically store the value. It first tests the value with its validator function. If that returns true, the value is stored. If it returns false, the object's failure function is called. That function may not return at all if it throws. If it returns true, the value is stored anyway (C<fail> may have modified it). If it returns false, no value is stored and the tied variable remains unmodified. In pseudocode,

  sub STORE {
      return storage = test or fail ? value : storage;
  }

That simple code is capable of many effects since both C<test> and C<fail> are capable of modifying C<value>, and C<fail> has enough information to retest.

Similarly, perl calls the tied class's C<FETCH()> method when it wishes to know the value of the tied variable. By default, C<Tie::Constrained> does not test the value in storage. That is so a tie may be left uninitialized and yet accept a value from a mutator (mutators call C<FETCH()> first to get the value they are to work on). If you want a more stringent tie, where the value must always pass the test, you may set the C<$STRICT> flag and every C<FETCH()> will apply the test or fail before returning the value. In pseudocode, C<FETCH()> looks like this:

  sub FETCH {
      fail if strict and not test storage;
      return storage;
  }

The C<TIESCALAR> class method is the constructor for the tie class. After sorting out what kind of arguments it is given, its behavior is similar to C<STORE()> as far as the application of C<test> or C<fail> to the initial value is concerned. The C<new> class method for constructing an unbound C<Tie::Constrained> is just an alias to C<TIESCALAR>. Unbound objects are used as templates for initializing ties as arguments to C<TIESCALAR>, C<new>, or the C<constrain> wrapper.

C<Tie::Constrained> does not make use of C<DESTROY> or C<UNTIE>. Subclasses should do whatever they need with those.


=head2 Subclassing C<Tie::Constrained>

C<Tie::Constrained> is intended as a fully usable class with an interface which is low-level enough to provide a flexible way of highjacking the mutation of variables. If users wish to have a more specialized and restrictive constraint class, Tie::Constrained is constructed to work as a base class, providing the framework for that.

The default fail handler dies loud in Tie::Constrained. If by default you would prefer to silently ignore bad mutations, you can subclass C<Tie::Constrained> like this:

  package Tie::Constrained::Quiet;
  use Tie::Constrained;
  use vars qw/@ISA/;
  @ISA = qw/Tie::Constrained/;
  *failure = \&ignore;
  1;

If you just wish to ensure that your constraints are always strict and can't be subverted without notice by tie object tricks,

  package Tie::Constrained::Strict;
  use Tie::Constrained;
  use vars qw/@ISA/;
  @ISA = ('Tie::Constrained');
  *STRICT = \1;
  1;

Similarly, $VERBOSE may be set for a debugging environment.

The C<valid> or C<failure> functions may be overridden with user code to replace the default test or fail handlers.

=head2 Tests and Handlers

<Tie::Constrained>'s conventions for tests and fail handlers are as follows.

For tests:

=over

=item *

A test is called with one argument, the value to be tested.

=item *

The value in the argument list is modifiable, an alias to a variable in the caller.

=item *

Modifications to the value through its alias will be seen in the caller and will be effective throughout the rest of the caller's processing.

=item *

If C<$STRICT> is set, C<FETCH> calls the test on the stored value, not a copy of it. Tests which modify values take note.

=item *

If the test returns false, a call to the fail handler follows immediately.

=item *

If the test returns true, the fail handler is never called and the caller's processing takes the test to have succeeded.

=back

For C<fail> handlers:

=over

=item *

A fail handler is called with three arguments, a code reference to the test which triggered the call, an alias to the value it triggered on, and an error identifier.

=item *

The test reference is passed as a convenience for advanced fail handlers. It may be ignored, used as an identifier, or called to retest a modified value.

=item *

As with tests, the value alias is modifiable, and modifications will be effective in the caller if the handler returns.

=item *

The error identifier is, in base C<Tie::Constrained>, a number from L<Errno>. A non-returning handler will typically set C<$!> to this value, though it could also be used to guide a recovery attempt.

=item *

A fail handler may throw instead of returning. That is the default behavior in Tie::Constrained, where no user handler is specified.

=item *

If the fail handler returns true, the value (possibly modified) will be accepted by STORE and TIESCALAR as a value for the tied variable and by FETCH as a valid return.

=item *

If the fail handler returns false, the tied variable remains unchanged.

=back

Good taste and good sense should prevail in designing a constrained variable. Simple handlers of the kind shown below in the examples are robust and predictable. Clearly, this mechanism has room for plenty of exotic behaviors, though. There is lots of room to experiment.

=head2 Included Tests and Handlers

There are a few pre-packaged tests and failure handlers available to Tie::Constrained. They are accessible by importing through the arguments to C<use Tie::Constrained>. The functions are listed in the L</FUNCTIONS> section, and the export tags in L</EXPORTS>

=head1 FUNCTIONS

=head2 Class Methods

=over

=item C<VERSION()> 

Reports the version number of C<Tie::Constrained>.

=item C<new(LIST)> 

Constructor for an unbound Tie::Constructor object. The arguments follow the same syntax as those following the package name in the C<tie> call. Typical usage,

  my $all_vowels =
      Tie::Constrained->new(sub {$_[0] !~ /[^aeiouy]/});

The returned C<Tie::Constrained> object may be used to initialize multiple vowel strings. The constructors perform a deep copy of the object, so subsequent changes are not reflected in earlier uses.

=item C<constrain( $var, $tc_obj)>

A convenience function which wraps a C<Tie::Constrained> binding. Ties C<$var> to the C<Tie::Constrained> object. Given a bound or unbound C<Tie::Constrained> object, C<constrain> admits the nice syntax,

  constrain( my $word, $all_vowels) or die $!;

=back

=head2 Stock Validators

Validators take one argument and return true if the argument is to be committed to the tied variable. A false return triggers the fail handler. Values written to C<$_[0]> will be seen and used by the caller. Treat that with delicacy, forget it, or have fun with it.
C<Tie::Constrained> includes two dummy validators described below.

=over

=item C<notest>

Null validator. Every modification is accepted. The fail handler is never called. This is the default test.

=cut

# dummy validators
sub notest { 1 }


=item C<deny>

No modification is accepted with this validator. The fail handler is always called.

=cut

sub deny   { 0 }

=item C<detaint>

This is not a validator itself, but is included as a useful componemt of validators. Called on the caller's argument list, it will detaint the first argument. C<detaint> always returns true. Example validator for an http URI from a tainted source:

  use Regexp::Common 'URI';
  sub is_http { $_[0] =~ /^$RE{URI}{HTTP}$/ and &detaint, 1 }

=back

=cut

sub detaint {
    $_[0] = () = $_[0] =~ /^(.*)$/s;
    1;
}

=head2 Stock Fail Handlers

Fail handlers are called with three arguments. The first is a reference to the test which triggered the failure. It may be used to test repair attempts, select actions, or whatever else your imagination can devise.
The second argument is the value which failed. As with tests, and with the same caveats, that value is modifiable through C<$_[1]> and changes to it will be effective in the caller.
The third argument is an error number. The convention is to take them by name from Errno.pm, and assign them to C<$!> in the handler.
C<Tie::Constrained> is equipped with four stock fail handlers. The default, C<death>, dies loudly through C<&Carp::croak> or C<&Carp::confess>. That is intended to support an exception style of error handling.

=over

=item C<death>

Croaks with an error message from the lowest level caller. If $VERBOSE is true, the message contains a full stack trace (C<confess>). The default fail handler, C<failure>, is an alias to C<death> for its effect as an exception with respect to C<eval>.

=cut

sub death {
    (my ($try, $val), $!) = @_;
    ($VERBOSE ? \&confess : \&croak)->('Constraint violation: ');
}

=item C<warning>

Issues C<warn> with respect to the loweat level caller. If $VERBOSE is true, warns with a full stack trace.

=cut

sub warning {
    (my ($try, $val), $!) = @_;
    ($VERBOSE ? \&cluck : \&carp)->('Constraint violation: ');
    0;
}


=item C<ignore>

Any modification passed to this handler is silently ignored. The old value of the tied variable is retained. In chained assignments, the old value will be passed along to the left.

=cut

sub ignore { $! = undef }

=item C<allow>

This handler overrides any validation test and allows the tied variable to take the proposed value.

=cut

sub allow  {
    $! = undef;
    1;
}

=item C<eraser>

Responds to a failed test by clearing error and undefining value of the tied variable.

=cut

sub eraser { not $! = $_[1] = undef; }

BEGIN {

=item C<valid($value)> 

This is the default validity test for C<Tie::Constrained> and those subclasses which honor its tie conventions. In the base class, where it is expected that each tie binding will carry its own test, it is an alias to the C<notest> function.

=cut

    *valid = \&notest;     # default test

=item C<failure( $test, $value, $error)> 

The default fail handler for C<Tie::Constrained> and its faithful subclasses. In C<Tie::Constrained>, it is an alias to C<death>, which throws a loud exception.

=cut

    *failure = \&death;    # default fail
}

=back

=cut

sub TIESCALAR {
    my $class = shift;

    my ($try, $val, $out) =
        ref $_[0] ne 'CODE' ?
        @{$_[0]}{qw/test value fail/} :
        @_;

    $try->($val) or ($out?$out:\&failure)->($try, $val, EINVAL)
        if defined $val;

    bless {
        test   => $try || \&valid,
        value  => $val,
        fail   => $out || \&failure
    },  $class;
}

sub STORE {
    my ($self, $value) = @_;
    $self->{value} = 
        $self->{'test'}->($value) ||
            $self->{'fail'}->($self->{'test'}, $value, EINVAL) ?
        $value : $self->{'value'};
}

sub FETCH {
    my $self = shift;
    &{$self->{'fail'}}($self->{'test'}, $self->{'value'}, EINVAL)
        if  $STRICT
            and ! &{$self->{'test'}}($self->{'value'});
    $self->{'value'}
}

sub DESTROY {}

sub UNTIE {}

BEGIN { *new = \&TIESCALAR }

sub constrain {
    return unless $_[1]->isa('Tie::Constrained');
    tie $_[0],
        ref($_[1]),
        $_[1];
}

=head2 EXPORTS

All the tests and fail handlers listed above are ordinary functions, not class or instance methods. They may all be imported from C<Tie::Constrained> by name. There are no default exports.

There are a few export tags which identify groups of functions. They are:

=over

=item C<:diagnostic>

C<death>, C<warning>,

=item C<:dummy>

C<notest>, C<deny>, C<ignore>, C<allow>

=item C<:all>

    C<EINVAL>,  C<EDOM>, C<ERANGE>, C<notest>, C<deny>, C<death>, C<warning>, C<ignore>, C<allow>, C<eraser>, C<constrain>

Everything in the @EXPORT_OK list

=item C<:error>

C<EINVAL>, C<EDOM>, C<ERANGE> (all imported to C<Tie::Constrained> from C<Errno>)

=back

=head1 EXAMPLES

Here are a few examples of C<Tie::Constrained> at work.

We'll first look at a few cases where we want a string to contain nothing but vowels.

  tie my $vowels, Tie::Constrained =>
      sub { not $_[0] =~ /[^aeiouy]/ },
      'ioyou'
      sub { $! = undef };

In that example, the fail handler squashes errors and returns false, causing invalid values to be silently ignored. The tied variable C<$vowels> will retain its old value.

The argument to a validation function is modifiable, opening the way for something more than validation.

  tie my $cons_killer, Tie::Constrained =>
      sub { $_[0] =~ tr/aeiouy//cd; 1 };
  $cons_killer = "googleplex";

which results in C<$cons_killer> taking the value C<ooee>, much to the confusion of some future maintainer. Increment operators have an interesting effect on $cons_killer. Those tricks may best be left out of unobfuscated code.

A case where argument modifiability is more defensible:

  tie my $pristine, Tie::Constrained =>
      sub { $_[0] !~ /[^aeiouy]/ and &detaint };

There, we modify the taint property of a copy of the data, not the value itself. The C<detaint> function is exportable from C<Tie::Constrained>. Note that the old-style sub call is intended here, though C<detaint(@_)> would have done as well.

Fail handlers are also capable of modifying the proposed value for a tied variable:

  tie my $all_or_nothing, Tie::Consrained =>
      sub { $_[0] =~ /$re/ },
      undef,
      sub { $_[0] = undef; 1 };

With that, a failed assignment or mutation will leave the tied variable undefined.

Other modules are a rich source of tests. Suppose we obtain what is supposed to be an http URI from an untrusted source. Drawing on C<Regexp::Common>, we say,

  use Tie::Constrained qw/detaint/;
  use Regexp::Common qw/URI/;
  tie my $address, Tie::Constrained =>
      sub { $_[0] =~ /^$RE{URI}{HTTP}$/ and &detaint }
      undef,
      sub { $_[0] = undef; 1 };



Tie::Constrained is not limited to the values of ordinary scalars. Here is an example where variable is constrained to be a CGI query object. This usage also does the error handling for the CGI constructor.

  use CGI;
  tie my $query, Tie::Constrained =>
      sub { $_[0]->isa('CGI') },
      CGI->new;

That is error-handling that keeps on protecting. Later assignment to any value not a CGI instance will carry the death penalty.

=head1 PREREQUISITES

In use, C<Tie::Constrained> depends on

=over

=item C<Carp>

=item C<Errno>

=item C<Exporter>

=back

All are from the perl core.

Pre-installation testing demands:

=over

=item C<Test::Harness>

=item C<Test::More>

=item C<Test::Simple>

=back

Some tests use other modules. Those tests will be skipped if the needed modules are not available.

=head1 TODO

I am uneasy about the design of C<FETCH> under $STRICT. Its current behavior should not be regarded as a stable api yet. The version 1.0 release will not happen until that is resolved.

C<$STRICT> should be a property of each object, not a global flag. That is another goal for version 1.0.

I would like to expand the L</EXAMPLES> section and split it off to its own cookbook pod, with an accompanying directory of example code..

=head1 AUTHOR

Zaxo, C<< <zaxo@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tie-constrained@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Joshua ben Jore (C<< <jjore@cpan.org> >>), for the initial packaging and test suite, testing and patches for compatibility with older perl, thanks!

The Monks at the Monastery, L<http://perlmonks.org>, who saw it first.

=head1 COPYRIGHT & LICENSE

Copyright Zaxo (Tom Leete), 2004,2005, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
