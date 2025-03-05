#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   eval { require Test::Memoryleak } or
      plan skip_all => "No Test::Memoryleak";

   Test::Memoryleak->import;
}

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

no_leak {
   # Make these all lexicals to maximise the potential for a leak
   my $offset = 1;
   my $length = 2;
   my $replacement = "New value";

   substr( $str, $offset, $length ) = $replacement;
} 'substr lvalue does not leak';

Test::NoWarnings::had_no_warnings;
done_testing;
