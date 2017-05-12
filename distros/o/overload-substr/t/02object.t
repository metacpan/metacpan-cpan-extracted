#!/usr/bin/perl -w

use strict;
use Test::More tests => 10 + 1;
use Test::NoWarnings;

package SimpleString;

use overload::substr substr => \&_substr;

sub new
{
   my $class = shift;
   my ( $str ) = @_;
   return bless {
      str => $str,
   }, $class;
}

my @substr_args;
my $substr_return;
sub _substr
{
   my $self = shift;
   @substr_args = @_;

   return $substr_return;
}

package main;

my $str = SimpleString->new( "Hello, world" );
my $s;

$substr_return = "Hello";

$s = substr( $str, 0, 5 );
is( $s, "Hello", 'substr extraction' );

is_deeply( \@substr_args,
           [ 0, 5 ],
           '@args to substr extraction' );

substr( $str, 0, 5, "Goodbye" );
is_deeply( \@substr_args,
           [ 0, 5, "Goodbye" ],
           '@args to substr replacement' );

substr( $str, 9, 0 ) = "cruel ";
is_deeply( \@substr_args,
           [ 9, 0, "cruel " ],
           '@args to substr replacment by lvalue' );

# Test an OPf_MOD call being fetched
sub identity { return $_[0] }

$substr_return = "Result";
$s = identity( substr( $str, 0, 6 ) );
is( $s, "Result", 'substr result by OPf_MOD get' );
is_deeply( \@substr_args,
           [ 0, 6 ],
           '@args to OPf_MOD get' );

# Now lets just assert that non-string values work successfully
$substr_return = [ "return" ];
$s = substr( $str, 1, 2 );
is_deeply( $s,
           [ "return" ],
           'non-string substr extraction' );

substr( $str, 3, 4, [ "replace call" ] );
is_deeply( \@substr_args,
           [ 3, 4, [ "replace call" ] ],
           '@args to non-string substr replacement' );

substr( $str, 5, 6 ) = [ "replace lvalue" ];
is_deeply( \@substr_args,
           [ 5, 6, [ "replace lvalue" ] ],
           '@args to non-string substr replacement by lvalue' );

substr( $str, 8 ) = [ "replace trail lvalue" ];
is_deeply( \@substr_args,
           [ 8, undef, [ "replace trail lvalue" ] ],
           '@args to non-string 2-arg substr replacement by lvalue' );
