#!/usr/bin/perl -w

use strict;
use Test::More tests => 2 + 1;
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

is_deeply( \@substr_args,
           [ 0, 5 ],
           '@args to substr extraction' );
