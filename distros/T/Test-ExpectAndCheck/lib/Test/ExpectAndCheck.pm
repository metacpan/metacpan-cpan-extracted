#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Test::ExpectAndCheck;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp;

use List::Util qw( first );
use Scalar::Util qw( blessed );

use Test::Deep ();

use constant EXPECTATION_CLASS => "Test::ExpectAndCheck::_Expectation";

=head1 NAME

C<Test::ExpectAndCheck> - C<expect/check>-style unit testing with object methods

=head1 SYNOPSIS

   use Test::More;
   use Test::ExpectAndCheck;

   my ( $controller, $puppet ) = Test::ExpectAndCheck->create;

   {
      $controller->expect( act => 123, 45 )
         ->returns( 678 );

      is( $puppet->act( 123, 45 ), 678, '$puppet->act returns result' );

      $controller->check_and_clear( '->act' );
   }

   done_testing;

=head1 DESCRIPTION

This package creates objects that assist in writing unit tests with mocked
object instances. Each mocked "puppet" instance will expect to receive a given
list of method calls. Each method call is checked that it received the right
arguments, and will return a prescribed result. At the end of each test, each
object is checked to ensure all the expected methods were called.

=cut

=head1 METHODS

=cut

=head2 create

   ( $controller, $puppet ) = Test::ExpectAndCheck->create;

Objects are created in "entangled pairs" by the C<create> method. The first
object is called the "controller", and is used by the unit testing script to
set up what method calls are to be expected, and what their results shall be.
The second object is the "puppet", the object to be passed to the code being
tested, on which the expected method calls are (hopefully) invoked. It will
have whatever interface is implied by the method call expectations.

=cut

sub create
{
   my $class = shift;

   my $controller = bless {
      expectations => [],
   }, $class;
   my $puppet = Test::ExpectAndCheck::_Obj->new( $controller );

   return ( $controller, $puppet );
}

=head2 expect

   $exp = $controller->expect( $method, @args )

Specifies that the puppet will expect to receive a method call of the given
name, with the given arguments.

The argument values are compared using L<Test::Deep/cmp_deeply>. Values can
be specified literally, or using any of the "Special Comparisons" defined by
L<Test::Deep>.

The test script can call the L</returns> or L</throws> methods on the
expectation to set what the result of invoking this method will be.

=cut

sub expect
{
   my $self = shift;
   my ( $method, @args ) = @_;

   my ( undef, $file, $line ) = caller(1);
   defined $file or ( undef, $file, $line ) = caller(0);

   push @{ $self->{expectations} }, my $exp = $self->EXPECTATION_CLASS->new(
      $method => [ @args ], $file, $line,
   );

   return $exp;
}

sub _stringify
{
   my ( $v ) = @_;
   if( !defined $v ) {
      return "undef";
   }
   elsif( blessed $v and $v->isa( "Test::Deep::Ignore" ) ) {
      return "ignore()";
   }
   elsif( $v =~ m/^-?[0-9]+$/ ) {
      return sprintf "%d", $v;
   }
   elsif( $v =~ m/^[\x20-\x7E]*\z/ ) {
      $v =~ s/([\\'])/\\$1/g;
      return qq('$v');
   }
   else {
      if( $v =~ m/[^\n\x20-\x7E]/ ) {
         # string contains something non-printable; just hexdump it all
         $v =~ s{(.)}{sprintf "\\x%02X", ord $1}gse;
      }
      else {
         $v =~ s/([\\'\$\@])/\\$1/g;
         $v =~ s{\n}{\\n}g;
      }
      return qq("$v");
   }
}

sub _stringify_args
{
   join ", ", map { _stringify $_ } @_;
}

sub _call
{
   my $self = shift;
   my ( $method, @args ) = @_;

   my $e;
   $e = first { !$_->_called } @{ $self->{expectations} } and
      $e->_consume( $method, @args ) or do {
         my $message = Carp::shortmess( "Unexpected call to ->$method(${\ _stringify_args @args })" );
         $message .= "... while expecting " . $e->_stringify if $e;
         $message .= "... after all expectations done" if !$e;
         die "$message.\n";
      };

   return $e->_result;
}

=head2 check_and_clear

   $controller->check_and_clear( $name );

Checks that by now, every expected method has been called, and emits a new
test output line via L<Test::Builder>. Regardless, the expectations are also
cleared out ready for the start of the next test.

=cut

sub check_and_clear
{
   my $self = shift;
   my ( $name ) = @_;

   my $builder = Test::Builder->new;
   local $Test::Builder::Level = $Test::Builder::Level + 1;

   $builder->subtest( $name, sub {
      my $count = 0;
      foreach my $exp ( @{ $self->{expectations} } ) {
         $exp->_check( $builder );
         $count++;
      }

      $builder->ok( 1, "No calls made" ) if !$count;
   });

   undef @{ $self->{expectations} };
}

package
   Test::ExpectAndCheck::_Expectation;

use List::Util qw( all );

use constant {
   METHOD  => 0,
   ARGS    => 1,
   FILE    => 2,
   LINE    => 3,
   CALLED  => 4,
   RETURNS => 5,
   THROWS  => 6,
   DIAG    => 7,
};

=head1 EXPECTATIONS

Each value returned by the L</expect> method is an "expectation", an object
that represents one expected method call, the arguments it should receive, and
the return value it should provide.

=cut

sub new
{
   my $class = shift;
   my ( $method, $args, $file, $line ) = @_;
   return bless [ $method, $args, $file, $line, 0 ], $class;
}

=head2 returns

   $exp->returns( @result )

Sets the result that will be returned by this method call.

=cut

sub returns
{
   my $self = shift;

   $self->[RETURNS] = [ @_ ];
   undef $self->[THROWS];

   return $self;
}

=head2 throws

   $exp->throws( $e )

Sets the exception that will be thrown by this method call.

=cut

sub throws
{
   my $self = shift;
   ( $self->[THROWS] ) = @_;

   return $self;
}

sub _consume
{
   my $self = shift;
   my ( $method, @args ) = @_;

   $method eq $self->[METHOD] or
      return 0;

   my ( $ok, $stack ) = Test::Deep::cmp_details( \@args, $self->[ARGS] );
   unless( $ok ) {
      $self->[DIAG] = Test::Deep::deep_diag( $stack );
      return 0;
   }

   $self->[CALLED]++;
   return 1;
}

sub _check
{
   my $self = shift;
   my ( $builder ) = @_;

   my $method = $self->[METHOD];
   $builder->ok( $self->[CALLED], "->$method(${\ Test::ExpectAndCheck::_stringify_args @{ $self->[ARGS] } })" );
   $builder->diag( $self->[DIAG] ) if defined $self->[DIAG];
}

sub _result
{
   my $self = shift;
   die $self->[THROWS] if defined $self->[THROWS];
   return unless $self->[RETURNS];
   return @{ $self->[RETURNS] } if wantarray;
   return $self->[RETURNS][0];
}

sub _called
{
   my $self = shift;
   return $self->[CALLED];
}

sub _stringify
{
   my $self = shift;
   return "->$self->[METHOD](${\( Test::ExpectAndCheck::_stringify_args @{ $self->[ARGS] } )}) at $self->[FILE] line $self->[LINE]";
}

package
   Test::ExpectAndCheck::_Obj;

our @CARP_NOT = qw( Test::ExpectAndCheck );

sub new
{
   my $class = shift;
   my ( $controller ) = @_;

   return bless [ $controller ], $class;
}

sub AUTOLOAD
{
   my $self = shift;
   ( our $AUTOLOAD ) =~ m/::([^:]+)$/;
   my $method = $1;

   return if $method eq "DESTROY";

   return $self->[0]->_call( $method, @_ );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
