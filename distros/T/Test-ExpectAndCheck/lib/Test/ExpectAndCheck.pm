#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

package Test::ExpectAndCheck 0.07;

use v5.14;
use warnings;

use Carp;

use List::Util qw( first );
use Scalar::Util qw( blessed );

use Test::Deep ();

use Exporter 'import';
our @EXPORT_OK = qw( namedargs );

use constant EXPECTATION_CLASS => "Test::ExpectAndCheck::_Expectation";

=head1 NAME

C<Test::ExpectAndCheck> - C<expect/check>-style unit testing with object methods

=head1 SYNOPSIS

=for highlighter language=perl

   use Test::More;
   use Test::ExpectAndCheck;

   my ( $controller, $mock ) = Test::ExpectAndCheck->create;

   {
      $controller->expect( act => 123, 45 )
         ->will_return( 678 );

      is( $mock->act( 123, 45 ), 678, '$mock->act returns result' );

      $controller->check_and_clear( '->act' );
   }

   done_testing;

=head1 DESCRIPTION

This package creates objects that assist in writing unit tests with mocked
object instances. Each mock instance will expect to receive a given list of
method calls. Each method call is checked that it received the right
arguments, and will return a prescribed result. At the end of each test, each
object is checked to ensure all the expected methods were called.

=head2 Verbose Mode

Sometimes when debugging a failing test it can be useful to see a log of which
expectations have been called. By setting the C<$VERBOSE> package variable to
a true value, extra printing will happen during the test.

   {
      local $Test::ExpectAndCheck::VERBOSE = 1;

      $controller->expect( ... );

      ...
   }

This is printed directly to C<STDERR> and is intended for temporary debugging
during development.

=cut

our $VERBOSE = 0;

=head1 METHODS

=cut

=head2 create

   ( $controller, $mock ) = Test::ExpectAndCheck->create;

Objects are created in "entangled pairs" by the C<create> method. The first
object is called the "controller", and is used by the unit testing script to
set up what method calls are to be expected, and what their results shall be.
The second object is the "mock", the object to be passed to the code being
tested, on which the expected method calls are (hopefully) invoked. It will
have whatever interface is implied by the method call expectations.

=cut

sub create
{
   my $class = shift;

   my $controller = bless {
      expectations => [],
      whenever     => {},
   }, $class;
   my $mock = Test::ExpectAndCheck::_Obj->new( $controller );

   return ( $controller, $mock );
}

=head2 expect

   $exp = $controller->expect( $method, @args );

Specifies that the mock will expect to receive a method call of the given
name, with the given arguments.

The argument values are compared using L<Test::Deep/cmp_deeply>. Values can
be specified literally, or using any of the "Special Comparisons" defined by
L<Test::Deep>. Additionally, the L</namedargs> function listed below can also
appear as the final argument test.

The test script can call the L</will_return> or L</will_throw> methods on the
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

=head2 whenever

   $exp = $controller->whenever( $method, @args );

I<Since version 0.05.>

Specifies that the mock might expect to receive method calls of the given name
with the given arguments. These expectations are not expired once called, nor
do they expect to be called in any particular order. Furthermore it is not a
test failure for one of these not to be invoked at all.

These expectations do not directly form part of the test assertions checked by
the L</check_and_clear> method, but they may be useful to assist the code
under test, such as providing support behaviours that it may rely on but would
make the test script too fragile if spelled out in full using a regular
C<expect>.

These expectations are only used as a fallback mechanism, if the next real
C<expect>-based expectation does not match a method call. Individual special
cases can still be set up using C<expect> even though a C<whenever> exists
that might also match it.

As with L</expect>, the argument values are compared using C<Test::Deep>, and
results can be set with L</will_return> or L</will_throw>.

=cut

sub whenever
{
   my $self = shift;
   my ( $method, @args ) = @_;

   my ( undef, $file, $line ) = caller(1);
   defined $file or ( undef $file, $line ) = caller(0);

   push @{ $self->{whenever}{$method} }, my $exp = $self->EXPECTATION_CLASS->new(
      $method => [ @args ], $file, $line,
   );

   return $exp;
}

sub _stringify
{
   my ( $v, $autoquote ) = @_;
   if( !defined $v ) {
      return "+undef" if $autoquote;
      return "undef";
   }
   elsif( blessed $v and $v->isa( "Test::Deep::Ignore" ) ) {
      return "ignore()";
   }
   elsif( blessed $v and $v->isa( "Test::ExpectAndCheck::_NamedArgsChecker" ) ) {
      my %args = %{ $v->{val} };
      return "namedargs(" .
         join( ", ", map { sprintf "%s => %s", _stringify($_, 1), _stringify($args{$_}) } sort keys %args )
         . ")";
   }
   elsif( $v =~ m/^-?[0-9]+$/ ) {
      return sprintf "%d", $v;
   }
   elsif( $autoquote and $v =~ m/^[[:alpha:]_][[:alnum:]_]*$/ ) {
      return $v;
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
   my $method = shift;
   my $args = \@_;

   my $e;
   $e = first { !$_->_called } @{ $self->{expectations} } and
      $e->_consume( $method, @$args ) and
      return $e->_result( $args );

   if( my $wh = first { $_->_consume( $method, @$args ) } @{ $self->{whenever}{$method} } ) {
      return $wh->_result( $args );
   }

   my $message = Carp::shortmess( "Unexpected call to ->$method(${\ _stringify_args @$args })" );
   $message .= "... while expecting " . $e->_stringify if $e;
   $message .= "... after all expectations done" if !$e;
   die "$message.\n";
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

   # Only clear the non-indefinite ones
   foreach my $method ( keys %{ $self->{whenever} } ) {
      my $whenevers = $self->{whenever}{$method};

      @$whenevers = grep { $_->{indefinitely} } @$whenevers;

      @$whenevers or delete $self->{whenever}{$method};
   }
}

=head1 FUNCTIONS

=head2 namedargs

   $cmp = namedargs(name => $val, ...)

I<Since version 0.07.>

This exportable function may be used as the final argument to an L</expect>
or L</whenever> expectation, to indicate that all of the remaining arguments
passed at that position should be treated like named parameters in a list of
key/value pairs. This makes then insensitive to the order that the values are
passed by the caller.

Each value given can be a literal value or a special comparison from
C<Test::Deep>.

For example, this simple expectation will fail 50% of the time due to hash
order randomisation:

   $controller->expect( m => x => "X", y => "Y" );

   my %args = ( x => "X", y => "Y" );
   $puppet->m( %args );

This is solved by using the C<namedargs()> function.

   use Test::ExpectAndCheck 'namedargs';

   $controller->expect( m => namedargs(x => "X", y => "Y") );

Additionally, positional arguments may appear before this call.

   $controller->expect( n => 1, 2, namedargs(x => "X", y => "Y") );
   $puppet->n( $one, $two, %args );

=cut

## named arg support
sub namedargs
{
   my %args = @_;
   return Test::ExpectAndCheck::_NamedArgsChecker->new( \%args );
}

package Test::ExpectAndCheck::_FirstAndFinalChecker
{
   use base 'Test::Deep::Cmp';

   sub init
   {
      my ( $self, @vals ) = @_;
      my $final = pop @vals;

      $self->{first} = \@vals;
      $self->{final} = $final;
   }

   sub descend
   {
      my ( $self, $got ) = @_;
      return 0 unless ref $got eq "ARRAY";
      my @got = @$got;

      foreach my $exp1 ( @{ $self->{first} } ) {
         return 0 unless Test::Deep::descend( shift @got, $exp1 );
      }

      return Test::Deep::descend( \@got, $self->{final} );
   }
}

package Test::ExpectAndCheck::_NamedArgsChecker
{
   use base 'Test::Deep::Hash';

   sub descend
   {
      my ( $self, $got ) = @_;
      return 0 unless ref $got eq "ARRAY";
      my %got = @$got;

      return $self->SUPER::descend( \%got );
   }
}

package
   Test::ExpectAndCheck::_Expectation;

use List::Util qw( all );

=head1 EXPECTATIONS

Each value returned by the L</expect> method is an "expectation", an object
that represents one expected method call, the arguments it should receive, and
the return value it should provide.

=cut

sub new
{
   my $class = shift;
   my ( $method, $args, $file, $line ) = @_;

   my $argcheck;
   if( @$args and ( ref $args->[-1] // "" ) eq "Test::ExpectAndCheck::_NamedArgsChecker" ) {
      $argcheck = Test::ExpectAndCheck::_FirstAndFinalChecker->new( @$args );
   }
   else {
      $argcheck = Test::Deep::array( $args );
   }

   return bless {
      method   => $method,
      args     => $args,
      argcheck => $argcheck,
      file     => $file,
      line     => $line,
   }, $class;
}

=head2 will_return

   $exp->will_return( @result );

I<Since version 0.04.>

Sets the result that will be returned by this method call.

This method used to be named C<returns>, which should be avoided in new code.
Uses of the old name will print a deprecation warning.

=cut

sub will_return
{
   my $self = shift;
   my @result = @_;

   return $self->will_return_using( sub { return @result } );
}

sub returns
{
   warnings::warnif deprecated => "Calling \$exp->returns() is now deprecated; use ->will_return instead";
   return shift->will_return( @_ );
}

=head2 will_return_using

   $exp->will_return_using( sub ($args) { ... } );

I<Since version 0.05.>

Sets the result that will be returned, calculated by invoking the code.

The code block is invoked at the time that a result is needed. It is invoked
with an array reference containing the arguments to the original method call.
This is especially useful for expectations created using L</whenever>.

I<Since version 0.06> the code block is passed a reference to the caller's
actual arguments array, and therefore can modify values in it if required -
e.g. when trying to mock functions such as C<open()> or C<sysread()> which
modify lvalues passed in as arguments.

There is no corresponding C<will_throw_using>, but an exception thrown by this
code will be seen by the calling code.

=cut

sub will_return_using
{
   my $self = shift;
   my ( $code ) = @_;

   $self->{gen_return} = $code;

   return $self;
}

=head2 will_throw

   $exp->will_throw( $e );

I<Since version 0.04.>

Sets the exception that will be thrown by this method call.

This method used to be named C<throws>, which should be avoided in new code.

=cut

sub will_throw
{
   my $self = shift;
   my ( $exception ) = @_;

   return $self->will_return_using( sub { die $exception } );
}

sub throws
{
   warnings::warnif deprecated => "Calling \$exp->throws() is now deprecated; use ->will_throw instead";
   return shift->will_throw( @_ );
}

=head2 will_also

   $exp->will_also( sub { ... } );

I<Since version 0.04.>

Adds extra code which is run when the expected method is called, in addition
to generating the result value or exception.

When invoked, the code body is invoked in void context with no additional
arguments.

=cut

sub will_also
{
   my $self = shift;
   push @{ $self->{also} }, @_;

   return $self;
}

=head2 indefinitely

   $exp->indefinitely;

I<Since version 0.05.>

On an expectation created using L</whenever>, this expectation will not be
cleared by L</check_and_clear>, effectively establishing its effects for the
entire lifetime of the test script.

On an expectation created using L</expect> this has no effect; such an
expectation will still be cleared as usual.

=cut

sub indefinitely
{
   my $self = shift;

   $self->{indefinitely}++;

   return $self;
}

sub _consume
{
   my $self = shift;
   my ( $method, @args ) = @_;

   $method eq $self->{method} or
      return 0;

   my ( $ok, $stack ) = Test::Deep::cmp_details( \@args, $self->{argcheck} );
   unless( $ok ) {
      $self->{diag} = Test::Deep::deep_diag( $stack );
      return 0;
   }

   print STDERR "[Test::ExpectAndCheck] called " . $self->_stringify . "\n"
      if $VERBOSE;

   $self->{called}++;
   return 1;
}

sub _check
{
   my $self = shift;
   my ( $builder ) = @_;

   my $method = $self->{method};
   $builder->ok( $self->{called}, "->$method(${\ Test::ExpectAndCheck::_stringify_args @{ $self->{args} } })" );
   $builder->diag( $self->{diag} ) if defined $self->{diag};
}

sub _result
{
   my $self = shift;
   my ( $args ) = @_;

   if( my $also = $self->{also} ) {
      $_->() for @$also;
   }

   my @result;
   @result = $self->{gen_return}->( $args ) if $self->{gen_return};
   return @result if wantarray;
   return $result[0];
}

sub _called
{
   my $self = shift;
   return $self->{called};
}

sub _stringify
{
   my $self = shift;
   return "->$self->{method}(${\( Test::ExpectAndCheck::_stringify_args @{ $self->{args} } )}) at $self->{file} line $self->{line}";
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
