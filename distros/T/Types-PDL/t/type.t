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

        for my $ttype (
            [ Piddle   => \&Piddle,   sub { PDL->new( $pdl_type, 1 ) } ],
            [ Piddle0  => \&Piddle0D, sub { PDL->new( $pdl_type ) } ],
            [ Piddle1D => \&Piddle1D, sub { PDL->new( $pdl_type, [ 1, 2 ] ) } ],
            [
                Piddle2D => \&Piddle2D,
                sub { PDL->new( $pdl_type, [ [ 1, 2 ] ] ) }
            ],
            [
                Piddle3D => \&Piddle3D,
                sub { PDL->new( $pdl_type, [ [ [ 1, 2 ] ] ] ) }
            ],
          )
        {

            my ( $label, $type_generator, $pdl_generator ) = @$ttype;

            my $pdl = $pdl_generator->();

            subtest $label => sub {


                subtest 'PDL::Type' => sub {

                  SKIP: {

                        my $type;

                        ok(
                            lives {
                                $type
                                  = $type_generator->( [ type => $pdl_type ] )
                            },
                            'create type'
                          )
                          or skip "error creating type: $@", scalar keys %Type;

                        ok( $type->check( $pdl ), "correct type" );

                        ok( !$type->check( $Type{$_} ), "incorrect type: $_" )
                          for grep { $_ ne $ioname } keys %Type;
                    }
                };

                subtest 'type name' => sub {

                  SKIP: {

                        my $type;

                        ok(
                            lives {
                                $type
                                  = $type_generator->( [ type => $ioname ] )
                            },
                            'create type'
                          )
                          or skip "error creating type: $@", scalar keys %Type;

                        ok( $type->check( $pdl ), "correct type" );

                        ok( !$type->check( $Type{$_} ), "incorrect type: $_" )
                          for grep { $_ ne $ioname } keys %Type;
                    }
                };

            };

        }
    };
}


done_testing;
