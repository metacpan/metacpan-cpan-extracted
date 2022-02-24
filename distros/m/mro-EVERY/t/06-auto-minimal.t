use v5.22;
use Test::More;

use Symbol  qw( qualify_to_ref );

my $madness = 'mro::EVERY';
my $method  = 'frobnicate';

use_ok $madness, qw( autoload );

my $found   = [];

do
{
    for my $pkg ( qw( Foo Bar ) )
    {
        *{ qualify_to_ref $method => $pkg } 
        = sub { push @$found, $pkg };

        can_ok $pkg, $method;
    }

    package Foo;
    use mro;

    our @ISA = qw( Bar );

    package Bar;
    use mro;
};

my @testz = 
(
    [ Bar => ''             => [ qw( Bar        ) ] ]
  , [ Bar => 'EVERY'        => [ qw( Bar        ) ] ]
  , [ Bar => 'EVERY::LAST'  => [ qw( Bar        ) ] ]

  , [ Foo => ''             => [ qw( Foo        ) ] ]
  , [ Foo => 'EVERY'        => [ qw( Foo Bar    ) ] ]
  , [ Foo => 'EVERY::LAST'  => [ qw( Bar Foo    ) ] ]
);

for( @testz )
{
    my ( $pkg, $prefix, $expect ) = @$_;

    my $dispatch
    = $prefix
    ? join '::' => $prefix, $method
    : $method
    ;

    note "Dispatching: '$dispatch'";

    @$found = ();

    $pkg->$dispatch;

    is_deeply $found, $expect, "$pkg, $prefix"
    or diag "Found:\n", explain $found, "\nExpect:\n", $expect;
}

done_testing;
