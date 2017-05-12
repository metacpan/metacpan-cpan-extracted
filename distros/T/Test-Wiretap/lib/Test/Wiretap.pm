# Copyright (c) 2001-2008, Aruba Networks, Inc.
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use warnings;
package Test::Wiretap;
use base qw(Exporter);

use Carp;
use Storable qw(dclone);
use Class::Std;
use Test::Resub;

our $VERSION = '1.01';
our @EXPORT_OK = qw(wiretap);

# Simple delegators: this way, we present a unified interface, instead of having
# the caller write garbage like $wiretap->resub->args, $wiretap->resub->reset, etc.
use Class::Delegator
  send => [qw(
    args
    named_args
    method_args
    named_method_args
    called
    was_called
    not_called
  )],
  to => => '_my_resub';

my %resub :ATTR;
my %capture :ATTR( :init_arg<capture>, :default(0) );
my %return_values :ATTR;
my %return_context :ATTR;
my %deep_copy :ATTR( :init_arg<deep_copy>, :default(1) ); 

sub wiretap {
  my ($name, $code, %args) = @_;
  return Test::Wiretap->new({
    name => $name,
    before => $code,
    %args,
  });
}

sub _my_resub {
  my ($self) = @_;
  return $resub{ident $self};
}

sub BUILD {
  my ($self, $ident, $args) = @_;

  local $Carp::Internal{'Class::Std'} = 1;
  local $Carp::Internal{ do {__PACKAGE__} } = 1; 

  my $code_before = $args->{before} || sub {};
  my $code_after = $args->{after} || sub {};
  my $original_function = UNIVERSAL::can(_split_package_method($args->{name}));

  my $replacement = sub {
    my ($run_original, $capture, $run_after, @rv);
    my $wantarray = wantarray;

    if ($wantarray) {
      $run_original = sub { @rv = $original_function->(@_) };
      $capture = sub {
        push @{$return_values{$ident}}, ($deep_copy{$ident} ? dclone(\@rv) : \@rv);
        push @{$return_context{$ident}}, 'list';
      };
      $run_after = sub { $code_after->(\@_, \@rv, 'list') };
    } elsif (defined $wantarray) {
      $run_original = sub { $rv[0] = $original_function->(@_) };
      $capture = sub {
        push @{$return_values{$ident}}, ($deep_copy{$ident} ? dclone(\@rv) : \@rv);
        push @{$return_context{$ident}}, 'scalar';
      };
      $run_after = sub { $code_after->(\@_, $rv[0], 'scalar') };
    } else {
      $run_original = $original_function;
      $capture = sub {
        push @{$return_values{$ident}}, undef;
        push @{$return_context{$ident}}, 'void';
      };
      $run_after = sub { $code_after->(\@_, undef, 'void') };
    }

    $code_before->(@_);
    $run_original->(@_);
    $capture->();
    $run_after->(@_);

    return $wantarray ? @rv : $rv[0];
  };

  $resub{$ident} = Test::Resub->new({
    name => $args->{name},
    capture => $args->{capture},
    code => $replacement,
    _arg_slice($args, qw(deep_copy call)),
    (exists $args->{deep_copy} ? (deep_copy => $args->{deep_copy}) : ()),
  });
}

sub _arg_slice {
  my ($hash, @keys) = @_;
  return map { exists $hash->{$_} ? ($_ => $hash->{$_}) : () } @keys;
}

sub reset {
  my ($self) = @_;
  $self->_my_resub->reset;
  delete $return_values{ident $self};
  delete $return_context{ident $self};
}

sub return_values {
  my ($self) = @_;
  $self->_complain_if_no_capture('return values');
  return $return_values{ident $self} || [];
}

sub return_contexts {
  my ($self) = @_;
  $self->_complain_if_no_capture('return contexts');
  return $return_context{ident $self} || [];
}

sub _complain_if_no_capture {
  my ($self, $what) = @_;
  if (not $capture{ident $self}) {
    local $Carp::Internal{ do {__PACKAGE__} } = 1;
    carp "Must use the 'capture' flag to capture $what\n";
  }
}

# if we let Class::Std do this, then we either have to put ourselves and
# Class::Std in %Carp::Internal all the time, which is a side effect that the
# user is almost certainly not expecting; or the 'not ok 1000' message
# contains Test::Wiretap in its stack trace, which the user doesn't care about.
sub DEMOLISH {
  my ($self, $ident) = @_;
  local $Carp::Internal{ do {__PACKAGE__} } = 1;
  local $Carp::Internal{'Class::Std'} = 1;
  delete $resub{$ident};
}

# XXX copied from Test::Resub
sub _split_package_method {
  my ($method) = @_;
  my ($package, $name) = $method =~ /^(.+)::([^:]+)$/;
  return ($package, $name);
}

=head1 NAME

        Test-Wiretap - Listen in on a function

=head1 SYNOPSIS

        use Test::More tests => 3;
        use Test::Wiretap;

        {
          package InsultOMatic;
          sub insult {
            my ($class, $what) = @_;
            print "$what smells funny.\n";
            return 'stinky';
          }
        }

        my $tap = Test::Wiretap->new({
          name => 'InsultOMatic::insult',
          before => sub {
            print "Preparing for insult...\n";
          },
          after => sub {
            print "Insult complete!\n";
          },
        });

        InsultOMatic->insult('Limburger cheese');
        # prints:
        #  Preparing for insult...
        #  Limburger cheese smells funny.
        #  Insult complete!

        is( $tap->called, 1, "Insulted one thing" );
        is_deeply(
          $tap->method_args,
          [['Limburger cheese']],
          "Insulted cheese"
        );
        is_deeply(
          $tap->return_values,
          [['stinky']],
          "InsultOMatic agrees with me"
        );

=head1 CONSTRUCTOR

   use Test::Wiretap qw(wiretap);
   my $tap = wiretap 'package::method', sub { ... }, %args;

is equivalent to:

    use Test::Wiretap;
    my $rs = Test::Wiretap->new({
      name => 'package::method',
      before => sub { ... },
      %args,
    });

C<%args> can contain any of the following named arguments:

=over 4

=item B<name> (required)

The name of the function which is to be monitored.

=item B<before> (optional)

A code reference that will run before the tapped function. This function
receives the same @_ as the tapped function does.

=item B<after> (optional)

A code reference that will run after the tapped function. This function
receives three arguments: a reference to the tapped function's argument list,
a reference to the tapped function's return-values list,
and a third parameter indicating the context in which the tapped function was called.

The third parameter is one of 'list', 'scalar', or 'void'.

That is, if you have:
sub foo { map { $_ + 100 } @_ }

my $tap = Test::Wiretap->new({
  name => 'main::foo',
  before => sub { ... },
  after => sub { ... },
});

my @list = foo(1, 2, 3);

then the 'before' sub's @_ is (1, 2, 3),
and the 'after' sub's @_ is ([1, 2, 3], [101, 102, 103], 'list').

=item B<capture> (optional)

If true, arguments and return values will be captured. Arguments are available
using the B<args>, B<method_args>, B<named_args>, and B<named_method_args> methods.
See the Test::Resub documentation for details on those.

Default is not to capture arguments.

=item B<deep_copy> (optional)

If true, a deep copy of all arguments and return values will be made. Otherwise,
a shallow copy will be kept. This is useful if the tapped function modifies
receives a reference to a data structure that it modifies, for example.

Default is to deeply copy arguments and return values.

=back

=head1 METHODS

=over 4

=item B<called>

Returns the number of times the tapped subroutine/method was called.  The
C<reset> method clears this data.

=item B<was_called>

Returns the total number of times the tapped subroutine/method was called.
This data is B<not> cleared by the C<reset> method.

=item B<not_called>

Returns true if the tapped subroutine/method was never called.  The C<reset>
method clears this data.

=item B<reset>

Clears the C<called>, C<not_called>, C<return_values>, and C<args> data.

=item B<args>, B<method_args>, B<named_args>, B<named_method_args>

Returns data on how the replaced subroutine/method was invoked.
See the Test::Resub documentation for details.

=item B<return_values>

Returns a list of lists of the return values from the tapped function. Examples:

  sub foo { map { $_ + 100 } @_ }

  Invocations:                             C<return_values> returns:
  ----------------------------             -------------------------
    (none)                                   []
    foo(1, 2, 3)                             [[101, 102, 103]]
    foo(5); foo(6, 7)                        [[105], [106, 107]]

=item B<return_contexts>

  sub bar { }

  Invocations:                             C<return_contexts> returns:
  ----------------------------             -------------------------
    foo();                                   ['void']
    $x = foo();                              ['scalar']
    @a = foo();                              ['list']
    $x = foo(); @a = foo(); foo();           ['scalar', 'list', 'void']

=back

=head1 AUTHOR

AirWave Wireless, C<< <cpan at airwave.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-wiretap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Wiretap>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Wiretap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Wiretap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Wiretap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Wiretap>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Wiretap>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 AirWave Wireless, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Test::Wiretap
