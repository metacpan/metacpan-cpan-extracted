#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Test::Metrics::Any;

use strict;
use warnings;
use base qw( Test::Builder::Module );

use Metrics::Any::Adapter 'Test';
use Metrics::Any::Adapter::Test; # Eager load

our $VERSION = '0.01';

our @EXPORT = qw(
   is_metrics
   is_metrics_from
);

=head1 NAME

C<Test::Metrics::Any> - assert that code produces metrics via L<Metrics::Any>

=head1 SYNOPSIS

   use Test::More;
   use Test::Metrics::Any;

   use Module::Under::Test;

   is_metrics_from(
      sub { Module::Under::Test::do_a_thing for 1 .. 5 },
      {
         things_done => 5,
         time_taken => Test::Metrics::Any::positive,
      },
      'do_a_thing reported some metrics'
   );

   done_testing;

=head1 DESCRIPTION

This test module helps write unit tests which assert that the code under test
reports metrics via L<Metrics::Any>.

Loading this module automatically sets the L<Metrics::Any::Adapter> type to
C<Test>.

=cut

=head1 FUNCTIONS

=cut

=head2 is_metrics

   is_metrics( \%metrics, $name )

Asserts that the current value of every metric named in the given hash
reference is set to the value provided. Values can either be given as exact
numbers, or by one of the match functions mentioned in L</PREDICATES>.

Key names in the given hash should match the name format used by
L<Metrics::Any::Adapter::Test>. Name components are joined by underscores, and
any label tags are appended with spaces, as C<name:value>.

   {
      "a_basic_metric"               => 123,
      "a_labelled_metric label:here" => 456,
   }

This function only checks the values of metrics actually mentioned in the hash
given as its argument. It is not a failure for more metrics to have been
reported by the code under test than are mentioned in the hash. This helps to
ensure that new metrics added in code do not break existing tests that weren't
set up to expect them.

=cut

sub is_metrics
{
   my ( $expect, $testname ) = @_;
   my $tb = __PACKAGE__->builder;

   my %got = map { ( split m/\s*=\s*/, $_ )[0,1] } split m/\n/, Metrics::Any::Adapter::Test->metrics;

   foreach my $name ( sort keys %$expect ) {
      my $expectval = $expect->{$name};

      my $gotval = $got{$name};
      unless( defined $gotval ) {
         my $ret = $tb->ok( 0, $testname );
         $tb->diag( "Expected a metric called '$name' but didn't find one" );
         return $ret;
      }

      if( ref $expectval eq "Test::Metrics::Any::_predicate" ) {
         unless( $expectval->check( $gotval ) ) {
            my $ret = $tb->ok( 0, $testname );
            $tb->diag( "Expected metric '$name' to be ${\$expectval->message} but got $gotval" );
            return $ret;
         }
      }
      else {
         unless( $gotval == $expectval ) {
            my $ret = $tb->ok( 0, $testname );
            $tb->diag( "Expected metric '$name' to be $expectval but got $gotval" );
            return $ret;
         }
      }
   }

   return $tb->ok( 1, $testname );
}

=head2 is_metrics_from

   is_metrics_from( $code, \%metrics, $name )

Asserts the value of metrics reported by running the given piece of code.

The metrics in the test adapter are cleared, then the code is invoked, then
any metrics are checked in the same manner as L</is_metrics>.

=cut

sub is_metrics_from(&@)
{
   my ( $code, $expect, $testname ) = @_;

   Metrics::Any::Adapter::Test->clear;

   $code->();

   local $Test::Builder::Level = $Test::Builder::Level + 1;
   return is_metrics( $expect, $testname );
}

=head1 PREDICATES

As an alternative to expecting exact values for metrics, the following test
functions can be provided instead to assert that the metric is behaving
sensibly without needing to be an exact value. This could be useful for
example when the exact number of bytes or timing measures can vary between
test runs or platforms.

These predicates are not exported but must be invoked fully-qualified.

=cut

sub predicate { return bless [ @_ ], "Test::Metrics::Any::_predicate" }
{
   package Test::Metrics::Any::_predicate;
   sub check   { my $self = shift; $self->[1]->( shift ) }
   sub message { my $self = shift; $self->[0] }
}

=head2 positive

   metric => Test::Metrics::Any::positive

Asserts that the number is greater than zero. It must not be zero.

=cut

sub positive { predicate positive => sub { shift > 0 } }

=head2 at_least

   metric => Test::Metrics::Any::at_least( $n )

Asserts that the number at least that given - it can be equal or greater.

=cut

sub at_least { my ($n) = @_; predicate "at least $n" => sub { shift >= $n } }

=head2 greater_than

   metric => Test::Metrics::Any::greater_than( $n )

Asserts that the number is greater than that given - it must not be equal.

=cut

sub greater_than { my ($n) = @_; predicate "greater than $n" => sub { shift > $n } }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
