#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2022 -- leonerd@leonerd.org.uk

package Test::Future::IO;

use strict;
use warnings;

our $VERSION = '0.05';

use Carp;

use Test::ExpectAndCheck::Future 0.05;  # ->whenever
use Test::Deep ();

=head1 NAME

C<Test::Future::IO> - unit testing on C<Future::IO>

=head1 SYNOPSIS

   use Test::More;
   use Test::Future::IO;

   my $controller = Test::Future::IO->controller;

   {
      $controller->expect_syswrite_anyfh( "Hello, world\n" );
      $controller->expect_sysread_anyfh( 256 )
         ->will_done( "A string\n" );

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

   $exp = $controller->expect_sleep( $secs );

   $exp = $controller->expect_sysread( $fh, $len );
   $exp = $controller->expect_syswrite( $fh, $bytes );

For testing simpler code that does not operate on multiple filehandles, two
additional methods that ignore the filehandle argument may be more convenient:

   $exp = $controller->expect_sysread_anyfh( $len );
   $exp = $controller->expect_syswrite_anyfh( $bytes );

In each case the returned expectation object allows the test script to specify
what such an invocation should return.

   $exp->will_done( @result );

Expectations can make methods fail instead.

   $exp->will_fail( $message );
   $exp->will_fail( $message, $category, @details );

Expectations can be set to remain pending rather than completing.

   $exp->remains_pending;

As a convenience, a C<syswrite> expectation will default to returning a future
that will complete yielding its length (as is usual for successful writes),
and a C<sleep> expectation will return a future that completes yielding
nothing.

Testing event-based code with C<expect_sysread> can be fragile, as it relies
on exact ordering, buffer sizes, and so on. A more flexible approach that
leads to less brittle tests is to use a buffer around that filehandle that is
provided by the test module. The test module then intercepts all C<sysread>
method calls on the given filehandle to return data from that buffer:

   $controller->use_sysread_buffer( $fh );

   $controller->write_sysread_buffer( $fh, $data );

As a convenience for filling the sysread buffer at the right time, any
expectation returned by this module supports two extra methods for invoking
C<write_sysread_buffer> when another expectation completes:

   $exp->will_write_sysread_buffer( $fh, $data );

   $exp->will_write_sysread_buffer_later( $fh, $data );

These are both shortcuts for calling L</write_sysread_buffer> from within a
C<will_also> or C<will_also_later> code block.

=cut

my ( $controller, $obj ) = Test::Future::IO::_Controller->create;

my %sysread_buffers;

require Future::IO;
Future::IO->override_impl( $obj );

sub expect_sleep
{
   my $self = shift;
   my ( $secs ) = @_;

   return $controller->expect( sleep => $secs )
      ->will_done();
}

sub expect_sysread
{
   my $self = shift;
   my ( $fh, $len ) = @_;
   if( @_ == 1 ) {
      carp "->expect_sysread with one argument is now deprecated";
      ( $fh, $len ) = ( Test::Deep::ignore(), @_ );
   }

   return $controller->expect( sysread => $fh, $len );
}

sub expect_syswrite
{
   my $self = shift;
   my ( $fh, $bytes ) = @_;
   if( @_ == 1 ) {
      carp "->expect_syswrite with one argument is now deprecated";
      ( $fh, $bytes ) = ( Test::Deep::ignore(), @_ );
   }

   return $controller->expect( syswrite => $fh, $bytes )
      ->will_done( length $bytes );
}

sub expect_sysread_anyfh
{
   my $self = shift;
   $self->expect_sysread( Test::Deep::ignore() => @_ );
}

sub expect_syswrite_anyfh
{
   my $self = shift;
   $self->expect_syswrite( Test::Deep::ignore() => @_ );
}

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

=head2 use_sysread_buffer

   $controller->use_sysread_buffer( $fh );

I<Since version 0.05.>

This method enables a read buffer for a given filehandle, that provides an
alternative means of testing reading on a filehandle than using
C<expect_sysread>. Once enabled, C<< Future::IO->sysread >> calls on the given
filehandle handled internally by the test controller.

The sysread buffer is initially empty, and can be written to by
L</write_sysread_buffer>.

This is provided using a C<Test::ExpectAndCheck::Future> C<< ->whenever >>
expectation, which is returned by this method. This is useful in case you want
to call the C<< ->indefinitely >> method on it, meaning it will survive past
calls to L</check_and_clear>.

   $controller->use_sysread_buffer( "FH" )
      ->indefinitely;

=cut

sub use_sysread_buffer
{
   my $self = shift;
   my ( $fh ) = @_;

   require Future::Buffer;

   # Not //= so that each test gets a new buffer
   my $buffer = $sysread_buffers{$fh} = Future::Buffer->new;

   return $controller->whenever( sysread => $fh, Test::Deep::ignore() )
      ->will_return_using( sub {
         my ( $args ) = @_;
         return $buffer->read_atmost( $args->[1] );
      });
}

=head2 write_sysread_buffer

   $controller->write_sysread_buffer( $fh, $data );

I<Since version 0.05.>

Appends more data to the sysread buffer previously established by the
L</use_sysread_buffer>.

Typically this is performed either initially as part of test setup, or later
as a side-effect of other expectations completing.

For example:

   $controller->use_sysread_buffer( "FH" );

   $controller->expect_syswrite( "FH", "Question?\n" )
      ->will_write_sysread_buffer_later( "FH", "Answer!\n" );

=cut

sub write_sysread_buffer
{
   my $self = shift;
   my ( $fh, $data ) = @_;

   my $buffer = $sysread_buffers{$fh} or
      croak "Filehandle $fh is not managed by a Test::Future::IO buffer";

   $buffer->write( $data );
}

{
   package Test::Future::IO::_Controller;
   use base qw( Test::ExpectAndCheck::Future );
   use constant EXPECTATION_CLASS => "Test::Future::IO::_Expectation";
}

{
   package Test::Future::IO::_Expectation;
   use base qw( Test::ExpectAndCheck::Future::_Expectation );

   sub will_write_sysread_buffer
   {
      my $self = shift;
      my ( $fh, $data ) = @_;

      return $self->will_also( sub {
         Test::Future::IO->write_sysread_buffer( $fh, $data );
      });
   }

   sub will_write_sysread_buffer_later
   {
      my $self = shift;
      my ( $fh, $data ) = @_;

      return $self->will_also_later( sub {
         Test::Future::IO->write_sysread_buffer( $fh, $data );
      });
   }
}

=head1 TODO

=over 4

=item *

Provision of a mock filehandle object to assist unit tests.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
