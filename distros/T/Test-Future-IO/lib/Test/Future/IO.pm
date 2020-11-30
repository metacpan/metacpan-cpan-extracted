#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Test::Future::IO;

use strict;
use warnings;

our $VERSION = '0.02';

use Test::ExpectAndCheck::Future;
use Test::Deep ();

=head1 NAME

C<Test::Future::IO> - unit testing on C<Future::IO>

=head1 SYNOPSIS

   use Test::More;
   use Test::Future::IO;

   my $controller = Test::Future::IO->controller;

   {
      $controller->expect_syswrite( "Hello, world\n" );
      $controller->expect_sysread( 256 )
         ->returns( "A string\n");

      code_under_test();

      $controller->check_and_clear( 'code under test did correct IO' );
   }

=head1 DESCRIPTION

This package provides a means to apply unit testing around code which uses
L<Future::IO>. It operates in an "expect-and-check" style of mocking,
requiring the test script to declare upfront what methods are expected to be
called, and what values they return.

=cut

=head1 EXPECTATIONS

Each of the actual C<Future::IO> methods has a corresponding expectation
method on the controller object, whose name is prefixed with C<expect_>. A
single call to one of these methods by the unit test script represents a
single call to a C<Future::IO> method that the code under test is expected to
make. The arguments to the expectation method should match those given by the
code under test. Each expectation method returns an object which has
additional methods to control the behaviour of that invocation.

   $exp = $controller->expect_sleep( $secs )

   $exp = $controller->expect_sysread( $len )
   $exp = $controller->expect_syswrite( $bytes )

Note that the C<sysread> and C<syswrite> expectations currently ignore the
filehandle argument. This behaviour B<will> be changed in a future version. To
keep this behaviour use the following methods instead:

   $exp = $controller->expect_sysread_anyfh( $len )
   $exp = $controller->expect_syswrite_anyfh( $bytes )

The returned expectation object allows the test script to specify what such an
invocation should return.

   $exp->returns( @result )

Expectations can make methods fail instead.

   $exp->fails( $message )
   $exp->fails( $message, $category, @details )

=cut

my ( $controller, $obj ) = Test::ExpectAndCheck::Future->create;

require Future::IO;
Future::IO->override_impl( $obj );

sub expect_sleep
{
   my $self = shift;
   my ( $secs ) = @_;

   return $controller->expect( sleep => $secs );
}

sub expect_sysread
{
   my $self = shift;
   my ( $len ) = @_;

   return $controller->expect( sysread => Test::Deep::ignore(), $len );
}

*expect_sysread_anyfh = \&expect_sysread;

sub expect_syswrite
{
   my $self = shift;
   my ( $bytes ) = @_;

   return $controller->expect( syswrite => Test::Deep::ignore(), $bytes )
      ->returns( length $bytes );
}

*expect_syswrite_anyfh = \&expect_syswrite;

=head1 METHODS

=cut

=head2 controller

   $controller = Test::Future::IO->controller;

Returns the control object, on which the various C<expect_*> methods and
C<check_and_clear> can be invoked.

=cut

sub controller { __PACKAGE__ }

=head2 check_and_clear

   $controller->check_and_clear( $name );

Checks that by now, every expected method has been called, and emits a new
test output line via L<Test::Builder>. Regardless, the expectations are also
cleared out ready for the start of the next test.

=cut

sub check_and_clear
{
   shift;
   my ( $name ) = @_;

   local $Test::Builder::Level = $Test::Builder::Level + 1;
   $controller->check_and_clear( $name );
}

=head1 TODO

=over 4

=item *

Configurable matching on filehandles. Provision of a mock filehandle object to
assist unit tests.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
