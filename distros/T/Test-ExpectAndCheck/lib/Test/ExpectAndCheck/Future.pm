#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2023 -- leonerd@leonerd.org.uk

package Test::ExpectAndCheck::Future 0.06;

use v5.14;
use warnings;
use base qw( Test::ExpectAndCheck );

use constant EXPECTATION_CLASS => "Test::ExpectAndCheck::Future::_Expectation";

=head1 NAME

C<Test::ExpectAndCheck::Future> - C<expect/check>-style unit testing with C<Future>-returning methods

=head1 SYNOPSIS

   use Test::More;
   use Test::ExpectAndCheck::Future;

   use Future::AsyncAwait;

   my ( $controller, $mock ) = Test::ExpectAndCheck::Future->create;

   {
      $controller->expect( act => 123, 45 )
         ->will_done( 678 );

      is( await $mock->act( 123, 45 ), 678, '$mock->act yields result' );

      $controller->check_and_clear( '->act' );
   }

   done_testing;

=head1 DESCRIPTION

This package creates objects that assist in writing unit tests with mocked
object instances. Each mocked instance will expect to receive a given list of
method calls. Each method call is checked that it received the right
arguments, and will return a L<Future> instance to yield the prescribed
result. At the end of each test, each object is checked to ensure all the
expected methods were called.

It is a variation of L<Test::ExpectAndCheck>, assistance around the results
of invoked methods. Every invoked method will return a L<Future> instance. The
L</will_done> or L</will_fail> method can then set the desired eventual result
of that future instance for each expectation.

These return instances are implemented using L<Test::Future::Deferred>, so
they are not immediately ready. Instead they will only become ready after a
toplevel C<await> expression or call to the C<get> method. This should help
unit tests to run similarly to real-world behaviour, where most futures
returned by real-world interfaces (such as IO systems) would not be
immediately ready. This behaviour can be switched off for individual
expectations by using the L</immediately> method.

=cut

package
   Test::ExpectAndCheck::Future::_Expectation;
use base qw( Test::ExpectAndCheck::_Expectation );

use Test::Future::Deferred;

use Carp;
our @CARP_NOT = qw( Test::ExpectAndCheck );

use constant {
   BEHAVE_NOFUTURE => 0,
   BEHAVE_DONE     => 1,
   BEHAVE_FAIL     => 2,
   BEHAVE_PENDING  => 3,
   BEHAVE_IMM_MASK => 4,
};

=head1 EXPECTATIONS

=cut

=head2 will_done

   $exp->will_done( @result );

I<Since version 0.04.>

Sets that method call will return a C<Future> instance which will succeed
with the given result.

=cut

sub will_done
{
   my $self = shift;

   my $imm = ( $self->{behaviour}[0] // 0 ) & BEHAVE_IMM_MASK;
   $self->{behaviour} = [ BEHAVE_DONE|$imm, @_ ];

   return $self;
}

# This was a bad API; "returns" on a T:EAC:Future expectation would set the
# future done result, not the immediate method call result
sub returns
{
   warnings::warnif deprecated => "Calling \$exp->returns() on a Future expectation is now deprecated; use ->will_done instead";
   return shift->will_done( @_ );
}

=head2 will_fail

   $exp->will_fail( $message, $category, @more );

I<Since version 0.04.>

Sets that method call will return a C<Future> instance which will fail
with the given message, and optionally category name and extra details.

=cut

sub will_fail
{
   my $self = shift;

   my $imm = ( $self->{behaviour}[0] // 0 ) & BEHAVE_IMM_MASK;
   $self->{behaviour} = [ BEHAVE_FAIL|$imm, @_ ];

   return $self;
}

sub fails
{
   warnings::warnif deprecated => "Calling \$exp->fails() is now deprecated; use ->will_fail instead";
   return shift->will_fail( @_ );
}

# Reset the future-type behaviour on these
sub will_return_using
{
   my $self = shift;

   $self->SUPER::will_return_using( @_ );
   $self->{behaviour} = [ BEHAVE_NOFUTURE ];

   return $self;
}

=head2 immediately

   $exp->will_done( ... )->immediately;

   $exp->will_fail( ... )->immediately;

I<Since version 0.02.>

Switches this expectation to return an immediate future, rather than a
deferred one.

=cut

sub immediately
{
   my $self = shift;

   $self->{behaviour}[0] |= BEHAVE_IMM_MASK;

   return $self;
}

=head2 remains_pending

   $exp->remains_pending;

I<Since version 0.03.>

Sets that the future returned by this method will not complete and simply
remain pending.

=cut

sub remains_pending
{
   my $self = shift;

   $self->{behaviour}[0] = BEHAVE_PENDING;

   return $self;
}

=head2 will_also_later

   $exp->will_also_later( sub { ... } );

I<Since version 0.04.>

Adds extra code which will run when the expected method is called, after the
returned future has completed. This is performed by the use of
C<Test::Future::Deferred>.

When invoked, the code body is invoked in void context with no additional
arguments.

=cut

sub will_also_later
{
   my $self = shift;

   push @{ $self->{also_later} }, @_;

   return $self;
}

sub _result
{
   my $self = shift;

   my $behaviour = $self->{behaviour} // [ 0 ];
   my ( $type, @args ) = @$behaviour;

   # $type == BEHAVE_NOFUTURE is zero and ignored
   if( $type == BEHAVE_DONE ) {
      $self->SUPER::will_return( Test::Future::Deferred->done_later( @args ) );
   }
   elsif( $type == (BEHAVE_DONE|BEHAVE_IMM_MASK) ) {
      $self->SUPER::will_return( Future->done( @args ) );
   }
   elsif( $type == BEHAVE_FAIL ) {
      $self->SUPER::will_return( Test::Future::Deferred->fail_later( @args ) );
   }
   elsif( $type == (BEHAVE_FAIL|BEHAVE_IMM_MASK) ) {
      $self->SUPER::will_return( Future->fail( @args ) );
   }
   elsif( $type == BEHAVE_PENDING ) {
      $self->SUPER::will_return( Future->new );
   }
   elsif( $type ) {
      die "TODO: Need result type $type";
   }

   if( my $also_later = $self->{also_later} ) {
      Test::Future::Deferred->done_later
         ->on_done( sub { $_->() for @$also_later } )
         ->retain;
   }

   return $self->SUPER::_result( @_ );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
