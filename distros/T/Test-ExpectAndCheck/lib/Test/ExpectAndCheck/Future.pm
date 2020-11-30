#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Test::ExpectAndCheck::Future;

use strict;
use warnings;
use base qw( Test::ExpectAndCheck );

our $VERSION = '0.01';

use constant EXPECTATION_CLASS => "Test::ExpectAndCheck::Future::_Expectation";

=head1 NAME

C<Test::ExpectAndCheck::Future> - C<expect/check>-style unit testing with C<Future>-returning methods

=head1 SYNOPSIS

   use Test::More;
   use Test::ExpectAndCheck::Future;

   my ( $controller, $puppet ) = Test::ExpectAndCheck::Future->create;

   {
      $controller->expect( act => 123, 45 )
         ->returns( 678 );

      is( $puppet->act( 123, 45 )->get, 678, '$puppet->act yields result' );

      $controller->check_and_clear( '->act' );
   }

   done_testing;

=head1 DESCRIPTION

This package creates objects that assist in writing unit tests with mocked
object instances. Each mocked "puppet" instance will expect to receive a given
list of method calls. Each method call is checked that it received the right
arguments, and will return a L<Future> instance to yield the prescribed
result. At the end of each test, each object is checked to ensure all the
expected methods were called.

It is a variation of L<Test::ExpectAndCheck>, assistance around the results
of invoked methods. Every invoked method will return a L<Future> instance. The
L</returns> or L</throws> method can then set the desired eventual result of
that future instance for each expectation.

=cut

package
   Test::ExpectAndCheck::Future::_Expectation;
use base qw( Test::ExpectAndCheck::_Expectation );

use constant {
   RETURNS => 3,
   FAILURE => 6,
};

=head1 EXPECTATIONS

=head2 returns

   $exp->returns( @result )

Sets the result that the future returned by this method call will yield.

=cut

=head2 fails

   $exp->fails( $message )
   $exp->fails( $message, $category, @details )

Sets the failure that the future returned by this method call will yield.

=cut

sub fails
{
   my $self = shift;

   $self->[FAILURE] = [ @_ ];
}

sub _result
{
   my $self = shift;
   require Future;

   return Future->fail( @{ $self->[FAILURE] } ) if $self->[FAILURE];
   return Future->done( @{ $self->[RETURNS] } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
