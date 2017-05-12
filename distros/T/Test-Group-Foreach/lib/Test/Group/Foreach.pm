package Test::Group::Foreach;
use strict;
use warnings;
our $VERSION = '0.03';

=head1 NAME

Test::Group::Foreach - repeat tests for several values

=head1 SYNOPSIS

  use Test::More;
  use Test::Group;
  use Test::Group::Foreach;

  next_test_foreach my $foo, 'f', 1, 2, 3;
  next_test_foreach my $bar, 'b', 1, 2, 3;

  test mytest => sub {
      # These tests will be repeated for each of the 9 possible
      # combinations of $foo in (1,2,3) and $bar in (1,2,3). 
      ok "$foo$bar" =~ /^\d+$/, "numeric";
      ok $foo+$bar < 6, "sum less than 6";
  };

  # This will result in a failure message like:
  #   Failed test 'sum less than 6 (f=3,b=3)'
  #   ...


  # Values can be given labels to be used in the test name in
  # place of the value, useful if you're working with values
  # that are not short printable strings...

  next_test_foreach my $foo, 'foo', [
      null  => "\0",
      empty => '',
      hash  => {foo => 1},
      array => ['bar'],
      long  => 'foo' x 1000,
  ];
  test mytest => sub {
      ok ref($foo) || length($foo) < 1000, "ref or short";
  };

  # This will result in a failure message like:
  #   Failed test 'ref or short (foo=long)'
  #   ...

=cut

use Carp;
use Test::Group qw(next_test_plugin);
use Test::NameNote;

our (@ISA, @EXPORT, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT = qw(next_test_foreach);
    @EXPORT_OK = qw(tgf_label);
}

=head1 FUNCTIONS

The following function is exported by default.

=over

=item next_test_foreach ( VARIABLE, NAME, VALUE [,VALUE...] )

Arranges for the next test group to be repeated for one or more values
of a variable.  A note will be appended to the name of each test run
within the group, specifying the value used.

The VARIABLE parameter must be a scalar, it will be set to each of the
specified values in turn.

The NAME parameter should be a short name that identifies this variable.
It will be used in the note added to the test name.  If NAME is undef
then no note will be added to the test name for this variable.  If NAME
is the empty string then the note will consist of just the value rather
than a C<name=value> pair.

The remaining parameters are treated as values to assign to the variable.
There must be at least one.  It's possible to specify labels to use in 
the test name for some or all of the values, by passing array references
containing label/value pairs.  The following examples are all equivalent:

=for test "equiv1" begin

  next_test_foreach( my $p, 'p', [
      foo  => 'foo',
      bar  => 'bar',
      null => "\0",
      long => 'foo' x 1000,
  ]);

=for test "equiv1" end

=for test "equiv2" begin

  next_test_foreach( my $p, 'p',
      [ foo  => 'foo' ],
      [ bar  => 'bar' ],
      [ null => "\0" ],
      [ long => 'foo' x 1000 ],
  );

=for test "equiv2" end

=for test "equiv3" begin

  next_test_foreach( my $p, 'p',
      'foo',
      'bar',
      [ null => "\0" ],
      [ long => 'foo' x 1000 ],
  );

=for test "equiv3" end

=for test "equiv4" begin

  next_test_foreach( my $p, 'p',
      'foo',
      'bar',
      [ null => "\0", long => 'foo' x 1000 ],
  );

=for test "equiv4" end

=cut

our %_value_to_label;

sub next_test_foreach (\$$@) {
    my $varref = shift;
    my $name   = shift;
    
    @_ or croak "empty value list invalid for next_test_foreach";
    my @vals;
    foreach my $valspec (@_) {
        if (ref $valspec eq 'ARRAY') {
            my @a = @$valspec;
            @a or croak "empty arrayref passed to next_test_foreach";
            @a % 2 and croak
                  "odd number of elts in arrayref passed to next_test_foreach";
            while (@a) {
                my $label = shift @a;
                my $value = shift @a;
                push @vals, [$label => $value];
            }
        } else {
            push @vals, ["$valspec" => $valspec];
        }
    }

    next_test_plugin {
        my $next = shift;

        foreach my $val (@vals) {
            $$varref = $val->[1];
            my $note;
            if (defined $name) {
                my $notetext = length $name ? "$name=$val->[0]" : $val->[0];
                $note = Test::NameNote->new($notetext);
            }
            local $_value_to_label{"$varref"} = $val->[0];
            $next->();
        }
    };
}

=back

The following function is not exported by default.

=over

=item tgf_label ( VARIABLE )

Returns the label associated with the current value of VARIABLE. Can only be
called from within a test group, and VARIABLE must be a scalar that is being
varied by next_test_foreach().

This is useful if you want your test to do something slightly differently
for some values, for example:

  use Test::Group::Foreach qw(next_test_foreach tgf_label);

  next_test_foreach my $x, 'x', [
    foo => [{asd => 0, r => 19}, 'foo'],
    bar => [{a => b}, ['bar'], [], {}],
    baz => [{x => y}, {p => q}],
  ];

  test mytest => sub {
      if (tgf_label $x eq 'bar') {
          # special handling for the 'bar' case ...
          ...
      }
      ...
  };


=cut

sub tgf_label (\$) {
    my $varref = shift;

    defined $_value_to_label{"$varref"} or croak
                                            "non-foreach scalar in tgf_label";

    return $_value_to_label{"$varref"};
}

=back

=head1 AUTHOR

Nick Cleaton, C<< <nick at cleaton dot net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nick Cleaton, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
