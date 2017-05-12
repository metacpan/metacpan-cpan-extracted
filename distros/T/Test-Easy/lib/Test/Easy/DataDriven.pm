package Test::Easy::DataDriven;
use base qw(Exporter);

use strict;
use warnings;

use Carp qw(confess);
use Test::Easy::DeepEqual qw(deep_equal);
use Scalar::Util qw(blessed);
use Hash::MostUtils qw(lkeys);
use Functional::Utility qw(hook_run y_combinator);

our @EXPORT = qw(run_where each_ok);

sub assert(&;$) {
  require Carp;
  Carp::confess pop() if ! shift->();
}

sub run_where {
  my $code = pop;
  my (@where) = @_;

  return y_combinator {
    my ($recurse) = @_;
    return sub {
      my $where = shift @where;
      my $to_run = scalar @where ? $recurse : $code;
      return run_then_restore(@$where, $to_run);
    };
  }->();
}

sub run_then_restore {
  my $code = pop;
  my (@args) = @_;

  assert { ! grep { ! ref($_) } lkeys @args } "error: you gave me a bare scalar - give me a scalar reference instead";

  my @restore;

  my %sg = (
    SCALAR => [
      sub {
        my ($r, $v) = @_;
        $$r = $v;
      },
      sub {
        my ($r, $v) = @_;
        return $$r;
      },
    ],
    ARRAY => [
      sub {
        my ($r, $v) = @_;
        $r = $$r if ref($r) eq 'REF';
        @$r = @$v;
      },
      sub {
        my ($r, $v) = @_;
        return [@$r];
      },
    ],
    HASH => [
      sub {
        my ($r, $v) = @_;
        $r = $$r if ref($r) eq 'REF';
        %$r = %$v;
      },
      sub {
        my ($r, $v) = @_;
        return +{%$r};
      },
    ],
  );

  return hook_run(
    before => sub {
      while (my ($r, $v) = splice @args, 0, 2) {
        my ($setter, $getter) = @{$sg{ref $r} || $sg{SCALAR}};
        push @restore, {ref => $r, value => $getter->($r, $v)};
        $setter->($r, $v);
      }
    },
    run => $code,
    after => sub {
      foreach (@restore) {
        my ($setter) = @{$sg{ref $_->{value}} || $sg{SCALAR}};
        $setter->($_->{ref}, $_->{value});
      }
    },
  );
}

sub each_ok (&@) {
  my $code = shift;

  local $_;

  my $index = 0;

  my @bad;
  foreach (@_) {
    my $orig = $_;
    my (@got) = $code->();

    my $ok = 1;
    my $expected;

    if (@got == 1) {
      $ok = !! $got[0];
      $expected = 'something true';
    } elsif (! _match($got[0], $got[1])) {
      $ok = 0;
      $expected = $got[1];
    }

    push @bad, {
      raw => $_,
      index => $index,
      got => $got[0],
      expected => $expected,
    } if ! $ok;

    $index++;
  }

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return Test::Easy::deep_ok( \@bad, [] );
}

sub _match {
  my ($got, $expected) = @_;
  if (ref($expected) eq 'Regexp') {
    return $got =~ $expected;
  } elsif (! scalar grep { ref } ($got, $expected)) {
    return $got eq $expected;
  } elsif (ref($got) eq ref($expected)) {
    return deep_equal($got, $expected);
  } else {
    confess "I don't know how to compare a '${\ref($got)}' to a '${\ref($expected)}'";
  }
}

1;

__END__

=head1 NAME

Test::Easy::DataDriven - express your test conditions in a data-driven manner

=head1 SYNOPSIS

This is one of the tests for this module, and shows what this module provides:

    use Test::Easy::DataDriven qw(run_where);

    my $foo = 'foo value';
    my $bar = sub { uc(shift()) };

    is( $foo, 'foo value', 'sanity test: $foo has correct default value' );
    is( $bar->($foo), 'FOO VALUE', 'sanity test: $bar upper-cases its args' );

    run_where(
        [\$foo => 'some different value'],
        [\$bar => sub { my $val = shift; $val =~ tr/aeiou//id; $val }],

        sub {
            is( $bar->($foo), 'sm dffrnt vl', '$foo and $bar swapped out' );
        },
    );

    is( $foo, 'foo value', '$foo is restored to its original value' );
    is( $bar->($foo), 'FOO VALUE', '$bar is restored to its original value' );

At the expense of some extra syntax surrounding your test, you gain the ability to locally set test variables to a given
value for your testing code, and then have the variables restored to their original values once your code is done.

=head1 DESCRIPTION

Often times when you're writing tests you end up with variables that you'd like to inspect after you've done something
interesting in your test - and then you need to reset those variables to their default values before your next test.
If you forget to reset one of the variables you're inspecting, your test ends up being invalid. I generally only notice
the tests are invalid after debugging some production issue.

Being able to gloss away the notion of "set these variables to these values for the scope of this test, then reset them
back to their previous values" makes your tests more legible, and exposes duplicative - or worse yet, uncovered - test
conditions.

Here's an example of an admittedly synthetic test which doesn't use Test::Easy::DataDriven's run_where():

First, here's the code under test

    package Somewhere::Beyond;

    # For the sake of not representing these as functions which I then monkey-patch using Test::Resub,
    # I'm expressing these as variables. I did warn you this example is pretty synthetic, right? :)
    our $tide_is_rising;
    our $sun_has_set;

    sub the_sea {
        if ($Somewhere::Beyond::tide_is_rising) {
            return 'my lover is running away from a tidal wave';
        } elsif ($Somewhere::Beyond::sun_has_set) {
            return 'my lover is slumbering';
        } else {
            return 'my lover stands on golden sands';
        }
    }

To test this we'll want to test 3 different conditions. Let's take a stab at it:

    $Somewhere::Beyond::tide_is_rising = 1;
    like( Somewhere::Beyond->the_sea, qr/running away.*tidal wave/, 'my lover fears water' );

    $Somewhere::Beyond::sun_has_set = 1;
    like( Somewhere::Beyond->the_sea, qr/slumbering/, 'my lover is narcoleptic' );

    $Somewhere::Beyond::tide_is_rising = $Somewhere::Beyond::sun_has_set = 0;
    like( Somewhere::Beyond->the_sea, qr/my lover stands on golden sands/, 'and watches the ships go sailing' );

And here's our same test expressed using this module:

    run_where(
        [\$Somewhere::Beyond::tide_is_rising => 1],
        [\$Somewhere::Beyond::sun_has_set => 1],
        sub {
            like( Somewhere::Beyond->the_sea, qr/running away.*tidal wave/, 'my lover fears water' );
        }
    );

    run_where(
        [\$Somewhere::Beyond::tide_is_rising => 0],
        [\$Somewhere::Beyond::sun_has_set => 1],
        sub {
            like( Somewhere::Beyond->the_sea, qr/slumbering/, 'my lover is narcoleptic' );
        }
    );

    run_where(
        [\$Somewhere::Beyond::tide_is_rising => 0],
        [\$Somewhere::Beyond::sun_has_set => 0],
        sub {
            like( Somewhere::Beyond->the_sea, qr/my lover stands on golden sands/, 'and watches the ships go sailing' );
        }
    );

This second set of tests provide some interesting documentation. Note that in the first set of tests, the behavior
of $tide_is_rising and $sun_has_set both being set is not explicitly declared as being a rising-tide condition. In
the second set of tests, there is a test which says, "When the tide is rising and the sun is setting, my lover is
running away from the sea (not napping on the beach and drowning)."

The second set of tests also show that we've missed testing one condition, viz:

    run_where(
        [\$Somewhere::Beyond::tide_is_rising => 1],
        [\$Somewhere::Beyond::sun_has_set => 0],
        sub {
            like( Somewhere::Beyond->the_sea, qr/running away.*tidal wave/, 'my lover fears water' );
        }
    );

In practice I tend to express these four tests in a more compact fashion:

    use Test::Easy qw(each_ok);
    use Test::Easy::DataDriven qw(run_where);

    each_ok {                                            # Apply this block to the following list and run tests on return values.
        my $got = run_where(                             # locally set vars as I've declared, then run this code to generate a $got
            @{$_->{vars}},
            sub { Somewhere::Beyond->the_sea },          # This is the line of code under test.
        );
        return ($got, $_->{exp});                        # each_ok() will make sure $got and $_->{exp} match in some fashion.
    } ({
        vars => [
            [\$Somewhere::Beyond::tide_is_rising => 1],
            [\$Somewhere::Beyond::sun_has_set    => 0],
        ],
        exp => qr/running away.*tidal wave/,
    }, {
        vars => [
            [\$Somewhere::Beyond::tide_is_rising => 1],
            [\$Somewhere::Beyond::sun_has_set    => 1],
        ],
        exp => qr/running away.*tidal wave/,
    }, {
        vars => [
            [\$Somewhere::Beyond::tide_is_rising => 0],
            [\$Somewhere::Beyond::sun_has_set    => 1],
        ],
        exp => qr/slumbering/,
    }, {
        vars => [
            [\$Somewhere::Beyond::tide_is_rising => 0],
            [\$Somewhere::Beyond::sun_has_set    => 0],
        ],
        exp => qr/stands on golden sands/,
    });

=head1 TREATMENT OF OBJECTS

run_where() will attempt to locally update objects which are built around scalar, hash, and array references. More exotic objects such as
blessed code references and filehandles will cause an exception.

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2012 Belden Lyman E<lt>belden@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

I originally developed run_where() while working at AirWave L<http://airwave.com>, a division of Aruba Networks, Inc. L<http://arubanetworks.com>.
Gerald Lai <glai@gmail.com> helped design the declarative-style interface for run_where(). I have faithfully reimplemented run_where() in its current
form, supported in time and spirit by Shutterstock, Inc. L<http://code.shutterstock.com>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5 itself.

=cut
