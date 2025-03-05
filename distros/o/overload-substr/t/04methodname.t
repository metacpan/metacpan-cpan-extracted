#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::NoWarnings;

package SimpleString;

use overload::substr substr => "_substr";

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

is( \@substr_args,
    [ 0, 5 ],
    '@args to substr extraction' );

Test::NoWarnings::had_no_warnings;
done_testing;
