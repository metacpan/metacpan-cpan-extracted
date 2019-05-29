#! perl

use Test2::V0;

use Types::PDL -types;

use PDL::Lite;
use PDL::Types ();


my @pdl_types
  = map { PDL::Type->new( PDL::Types::mapfld( $_ => 'ppsym', 'ioname' ) ) }
  PDL::Types::ppdefs;

my %Type = map { $_->ioname => PDL->new( $_ ) } @pdl_types;

for my $pdl_type ( @pdl_types ) {

    my $ioname = $pdl_type->ioname;

    subtest $ioname => sub {

        my $pdl = PDL->new( $pdl_type );
        my $ttype;

        subtest 'PDL::Type' => sub {

          SKIP: {

                ok( lives { $ttype = Piddle([ type => $pdl_type ]) },
                    'create type' )
                  or skip "error creating type: $@", scalar keys %Type;

                ok( $ttype->check( $pdl ), "correct type" );

                ok( !$ttype->check( $Type{$_} ), "incorrect type: $_" )
                  for grep { $_ ne $ioname } keys %Type;
            }
        };

        subtest 'type name' => sub {

          SKIP: {

                ok( lives { $ttype = Piddle[ type => $ioname ] },
                    'create type' )
                  or skip "error creating type: $@", scalar keys %Type;

                ok( $ttype->check( $pdl ), "correct type" );

                ok( !$ttype->check( $Type{$_} ), "incorrect type: $_" )
                  for grep { $_ ne $ioname } keys %Type;
            }
        };

    };
}


done_testing;
