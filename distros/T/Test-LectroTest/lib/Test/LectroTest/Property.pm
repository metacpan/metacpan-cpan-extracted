package Test::LectroTest::Property;
{
  $Test::LectroTest::Property::VERSION = '0.5001';
}

use strict;
use warnings;

use Carp;
use Filter::Util::Call;

use constant NO_FILTER => 'NO_FILTER';

=head1 NAME

Test::LectroTest::Property - Properties that make testable claims about your software

=head1 VERSION

version 0.5001

=head1 SYNOPSIS

 use MyModule;  # provides my_function_to_test

 use Test::LectroTest::Generator qw( :common );
 use Test::LectroTest::Property qw( Test );
 use Test::LectroTest::TestRunner;

 my $prop_non_neg = Property {
     ##[ x <- Int, y <- Int ]##
     $tcon->label("negative") if $x < 0;
     $tcon->label("odd")      if $x % 2;
     $tcon->retry             if $y == 0;  # 0 can't be used in test
     my_function_to_test( $x, $y ) >= 0;
 }, name => "my_function_to_test output is non-negative";

 my $runner = Test::LectroTest::TestRunner->new();
 $runner->run_suite(
     $prop_non_neg,
     # ... more properties here ...
 );

=head1 DESCRIPTION

B<STOP!> If you're just looking for an easy way to write and run unit
tests, see L<Test::LectroTest> first.  Once you're comfortable with
what is presented there and ready to delve into the full offerings of
properties, this is the document for you.

This module allows you to define Properties that can be checked
automatically by L<Test::LectroTest>.  A Property is a specification
of your software's required behavior over a given set of conditions.
The set of conditions is given by a generator-binding
specification. The required behavior is defined implicitly by a block
of code that tests your software for a given set of generated
conditions; if your software matches the expected behavor, the
block of code returns true; otherwise, false.

This documentation serves as reference documentation for LectroTest
Properties.  If you don't understand the basics of Properties yet,
see L<Test::LectroTest::Tutorial/OVERVIEW> before continuing.

=cut

BEGIN {
    use Exporter ( );
    our @ISA         = qw( Exporter );
    our @EXPORT      = qw( &Property );
    our @EXPORT_OK   = qw( &Property );
    our %EXPORT_TAGS = ( );
}
our @EXPORT_OK;
our @CARP_NOT = qw ( Test::LectroTest::TestRunner );


my %defaults = ( name => 'Unnamed Test::LectroTest::Property' );

=pod

=head2 Two ways to create Properties

There are two ways to create a property:

=over 4

=item 1

Use the C<Property> function to promote a block of code that contains
both a generator-binding specification and a behavior test into a
Test::LectroTest::Property object.  B<This is the preferred method.>
Example:

  my $prop1 = Property {
      ##[ x <- Int ]##
      thing_to_test($x) >= 0;
  }, name => "thing_to_test is non-negative";


=cut

sub Property(&&@) {
    my ($genspec_fn, $test_fn, @args) = @_;
    return Test::LectroTest::Property->new(
        inputs => $genspec_fn->(),
        test   => $test_fn,
        @args
    );
}

=pod

=item 2

Use the C<new> method of Test::LectroTest::Property and provide
it with the necessary ingredients via named parameters:

  my $prop2 = Test::LectroTest::Property->new(
      inputs => [ x => Int ],
      test   => sub { my ($tcon,$x) = @_;
                      thing_to_test($x) >= 0 },
      name   => "thing_to_test is non-negative"
  );

=back

=cut

my $pkg = __PACKAGE__;

sub new {
    my $class = shift;
    croak "$pkg: invalid list of named parameters: (@_)"
        if @_ % 2;
    my %args  = @_;
    croak "$pkg: test subroutine must be provided"
        if ref($args{test}) ne 'CODE';
    croak "$pkg: did not get a set of valid input-generator bindings"
        if ref($args{inputs}) ne "ARRAY";
    $args{inputs} = [$args{inputs}] unless ref $args{inputs}[0];
    my $inputs_list = [];
    my $last_vars;
    for my $inputs (@{$args{inputs}}) {
        croak "$pkg: did not get a set of valid input-generator bindings"
            if ref($inputs) ne "ARRAY" || @$inputs % 2;
        $inputs = { @$inputs };
        croak "$pkg: cannot use reserved name 'tcon' in a generator binding"
            if defined $inputs->{tcon};
        my @vars = sort keys %$inputs;
        croak "$pkg: each set of generator bindings must bind the same "
            . "set of variables but (@vars) does not match ($last_vars)"
            if $last_vars && $last_vars ne "@vars";
        $last_vars = "@vars";
        push @$inputs_list, $inputs;
    }
    delete $args{inputs};
    return bless { %defaults, inputs => $inputs_list, %args }, $class;
}


=pod

Both are equivalent, but the first is concise, easier to read, and
lets LectroTest do some of the heavy lifting for you.  The second is
probably better, however, if you are constructing property
specifications programmatically.

=head2 Generator-binding specification

The generator-binding specification declares that certain variables
are to be bound to certain kinds of random-value generators during
the tests of your software's behavior.  The number and kind of
generators define the "condition space" that is examined during
property checks.

If you use the C<Property> function to create your properties, your
generator-binding specification must come first in your code block,
and you must use the following syntax:

  ##[ var1 <- gen1, var2 <- gen2, ... ]##

Comments are not allowed within the specification, but you may
break it across multiple lines:

  ##[ var1 <- gen1,
      var2 <- gen2, ...
  ]##

or

  ##[
      var1 <- gen1,
      var2 <- gen2, ...
  ]##

Further, for better integration with syntax-highlighting IDEs,
the terminating C<]##> delimiter may be preceded by a hash
symbol C<#> and optional whitespace to make it appear like
a comment:

  ##[
      var1 <- gen1,
      var2 <- gen2, ...
  # ]##

On the other hand, if you use C<Test::LectroTest::Property-E<gt>new()>
to create your objects, the generator-binding specification takes the
form of an array reference containing variable-generator pairs that is
passed to C<new()> via the parameter named C<inputs>:

  inputs => [ var1 => gen1, var2 => gen2, ... ]

Normal Perl syntax applies here.


=head2 Specifying multiple sets of generator bindings

Sometimes you may want to repeat a property check with multiple sets
of generator bindings.  This can happen, for instance, when your
condition space is vast and you want to ensure that a particular
portion of it receives focused coverage while still sampling the
overall space.  For times like this, you can list multiple
sets of bindings within the C<##[> and C<]##> delimiters, like so:

  ##[ var1 <- gen1A, ... ],
    [ var1 <- gen1B, ... ],
    ... more sets of bindings ...
    [ var1 <- gen1N, ... ]##

Note that only the first and last set need the special delimiters.

The equivalent when using C<new()> is as follows:

  inputs => [ [ var1 => gen1A, ... ],
              [ var1 => gen1B, ... ],
              ...
              [ var1 => gen1N, ... ] ]

Regardless of how you declare the sets of bindings, each set must
provide bindings for the exact same set of variables.  (The
generators, of course, can be different.)  For example, this kind of
thing is illegal:

  ##[ x <- Int ], [ y <- Int ]##

The above is illegal because both sets of bindings must use I<x> or
both must use I<y>; they can't each use a different variable.

  ##[ x <- Int             ],
    [ x <- Int, y <- Float ]##

The above is illegal because the second set has an extra variable that
isn't present in the first.  Both sets must use exactly the same
variables.  None of the variables may be extra, none may be missing,
and all must be named identically across the sets of bindings.



=head2 Behavior test

The behavior test is a subroutine that accepts a test-controller
object and a given set of input conditions, tests your software's
observed behavior against the required behavior with respect to the
input conditions, and returns true or false to indicate acceptance or
rejection.  If you are using the C<Property> function to create your
property objects, lexically bound variables are created and loaded
with values automatically, per your input-generator specification, so
you can just go ahead and use the variables immediately:

  my $prop = Property {
    ##[ i <- Int, delta <- Float(range=>[0,1]) ]##
    my $lo_val = my_thing_to_test($i);
    my $hi_val = my_thing_to_test($i + $delta);
    $lo_val == $hi_val;
  }, name => "my_thing_to_test ignores fractions" ;

On the other hand, if you are using
C<Test::LectroTest::Property-E<gt>new()>, you must declare and
initialize these variables manually from Perl's C<@_> variable I<in
lexicographically increasing order> after receiving C<$tcon>, the test
controller object.  (This inconvenience, by the way, is why the former
method is preferred.)  The hard way:

  my $prop = Test::LectroTest::Property->new(
    inputs => [ i => Int, delta => Float(range=>[0,1]) ],
    test => sub {
        my ($tcon, $delta, $i) = @_;
        my $lo_val = my_thing_to_test($i);
        my $hi_val = my_thing_to_test($i + $delta);
        $lo_val == $hi_val
    },
    name => "my_thing_to_test ignores fractions"
  ) ;


=head2 Control logic, retries, and labeling

Inside the behavior test, you have access to a special variable
C<$tcon> that allows you to interact with the test controller.
Through C<$tcon> you can do the following:

=over 4

=item *

retry the current trial with different inputs (if you don't like the
inputs you were given at first)

=item *

add labels to the current trial for reporting purposes

=item *

attach notes and variable dumps to the current trial for diagnostic
purposes, should the trial fail

=back

(For the full details of what you can do with C<$tcon> see
the "testcontroller" section of L<Test::LectroTest::TestRunner>.)

For example, let's say that we have written a function C<my_sqrt> that
returns the square root of its input.  In order to check whether our
implementation fulfills the mathematical definition of square root, we
might specify the following property:

  my $epsilon = 0.000_001;

  Property {
      ##[ x <- Float ]##
      return $tcon->retry if $x < 0;
      $tcon->label("less than one") if $x < 1;
      my $sx = my_sqrt( $x );
      abs($sx * $sx - $x) < $epsilon;
  }, name => "my_sqrt satisfies defn of square root";

Because we don't want to deal with imaginary numbers, our square-root
function is defined only over non-negative numbers.  To make sure
we don't accidentally check our property "at" a negative number, we
use the following line to re-start the trial with a different
input should the input we are given at first be negative:

      return $tcon->retry if $x < 0;

An interesting fact is that for all values I<x> between zero and one,
the square root of I<x> is larger than I<x> itself.  Perhaps our
implementation treats such values as a special case.  In order to be
confident that we are checking this case, we added the following line:

      $tcon->label("less than one") if $x < 1;

In the property-check output, we can see what percentage of the
trials checked this case:

  1..1
  ok 1 - 'my_sqrt satisfies defn of square root' (1000 attempts)
  #   1% less than one

=head2 Trivial cases

Random-input generators may create some inputs that are trivial and
don't provide much testing value.  To make it easy to label such
cases, you can use the following from within your behavior tests:

    $tcon->trivial if ... ;

The above is exactly equivalent to the following:

    $tcon->label("trivial") if ... ;




=cut

sub import {
    Test::LectroTest::Property->export_to_level(
        1, grep {$_ ne NO_FILTER} @_ );
    return if grep {$_ eq NO_FILTER} @_;
    filter_add( _make_code_filter() );
}

sub _make_code_filter {
    my $content = "";
    sub {
        my $status = shift;
        if ( defined $status ? $status : ($status = filter_read()) ) {
            if (s| \#\# ( \[ .*?  ) \#*\s*\]\#\# |
                   "["._binding($1)."]]}"._body($1) |exs) {
                # 1-line decl
            }
            elsif (s| \#\# ( \[.* ) | "["._binding($1) |exs) {
                # opening of multi-line decl
                $content .= " $1";
            }
            elsif ($content &&
                   s| ^(.*?)\#*\s*\]\#\# |
                      _binding($1)."]]}"._body("$content$1") |exs) {
                # close of multi-line decl
                $content = "";
            }
            elsif ($content) {
                s/(.*)/_binding($1)/es;
                $content .= " $1";
            }
        }
        return $status;
    }
}

# convert bindinging operators ( <- ) into key arrows ( => )

sub _binding {
    my $s = shift;
    $s =~ s| <- | => |gx;
    return $s;
}

sub _body {
    my ($gen_decl_str) = @_;
    my @vars = $gen_decl_str =~ /(\w+)\s*<-/gs;
    @vars = sort keys %{{ map {($_,1)} @vars }}; # uniq | sort
    @vars = grep { 'tcon' ne $_ } @vars;  # disallow reserved var 'tcon'
    ' sub { my (' . join(',', map {"\$$_"} 'tcon', @vars) . ') = @_;';
}

1;

=pod

=head1 SEE ALSO

L<Test::LectroTest::Generator> describes the many generators and
generator combinators that you can use to define the test or
condition spaces that you want LectroTest to search for bugs.

L<Test::LectroTest::TestRunner> describes the objects that check your
properties and tells you how to turn their control knobs.  You'll want
to look here if you're interested in customizing the testing
procedure.


=head1 HERE BE SOURCE FILTERS

The special syntax used to specify generator bindings relies upon a
source filter (see L<Filter::Util::Call>).  If you don't want to use
the syntax, you can disable the filter like so:

    use Test::LectroTest::Property qw( NO_FILTER );

=head1 AUTHOR

Tom Moertel (tom@moertel.com)

=head1 INSPIRATION

The LectroTest project was inspired by Haskell's
QuickCheck module by Koen Claessen and John Hughes:
http://www.cs.chalmers.se/~rjmh/QuickCheck/.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2004-13 by Thomas G Moertel.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
