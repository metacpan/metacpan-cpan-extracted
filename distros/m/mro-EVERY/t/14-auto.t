use v5.22;
use Test::More;

use Symbol  qw( qualify_to_ref );

my $madness = 'mro::EVERY';
my $method  = 'frobnicate';

use_ok $madness, qw( autoload );

my $found   = [];

do
{
    for my $pkg ( qw( Up Left Rite Down ) )
    {
        my $auto    = sub { push @$found, $pkg  };
        my %subz    = 
        (
            AUTOLOAD    => $auto
          , $method     => $auto
        );

        my $can     = sub { $subz{ $_[1] } };

        *{ qualify_to_ref AUTOLOAD  => $pkg } = $auto;
        *{ qualify_to_ref can       => $pkg } = $can;

        can_ok $pkg, 'AUTOLOAD';
        can_ok $pkg, $method;
    }

    package Up;
    use mro;

    our @ISA = qw( Left Rite );

    package Left;
    use mro;

    our @ISA = qw( Down );

    package Rite;
    use mro;

    our @ISA = qw( Down );

    package Down;
    use mro;
};

my @testz = 
(
    [ Down  => ''            => [ qw( Down               ) ] ]
  , [ Down  => 'EVERY'       => [ qw( Down               ) ] ]
  , [ Down  => 'EVERY::LAST' => [ qw( Down               ) ] ]

  , [ Left  => ''            => [ qw( Left               ) ] ]
  , [ Left  => 'EVERY'       => [ qw( Left Down          ) ] ]
  , [ Left  => 'EVERY::LAST' => [ qw( Down Left          ) ] ]

  , [ Rite  => ''            => [ qw( Rite               ) ] ]
  , [ Rite  => 'EVERY'       => [ qw( Rite Down          ) ] ]
  , [ Rite  => 'EVERY::LAST' => [ qw( Down Rite          ) ] ]

  , [ Up    => ''            => [ qw( Up                 ) ] ]
  , [ Up    => 'EVERY'       => [ qw( Up Left Down Rite  ) ] ]
  , [ Up    => 'EVERY::LAST' => [ qw( Rite Down Left Up  ) ] ]
);

for( @testz )
{
    my ( $pkg, $prefix, $expect ) = @$_;

    my $dispatch
    = $prefix
    ? join '::' => $prefix, $method
    : $method
    ;

    note "$pkg->$dispatch\n", explain $expect;

    @$found = ();

    $pkg->$dispatch;

    is_deeply $found, $expect, "$pkg, $prefix"
    or diag "Found:\n", explain $found, "\nExpect:\n", $expect;
}

done_testing;
