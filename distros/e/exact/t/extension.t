use Test::More;
use Test::Exception;

my $version = ( $^V =~ /v\d+\.(\d+)/ ) ? $1 : 0;

SKIP: {
    skip( ": Perl $^V does not support extensions", 1 ) if ( $version < 14 );

    BEGIN {
        package exact::____test;

        use exact;

        sub import {
            my ( $self, $caller, $params ) = @_;
            {
                no strict 'refs';
                *{ $caller . '::thx' } = \&thx;
            }
        }

        sub thx {
            return 1138;
        }

        package main;

        $INC{'exact/____test.pm'} = 1;
    }

    use_ok( 'exact', '____test' );

    my $thx = 0;
    lives_ok( sub { $thx = thx() }, 'thx() imported OK' );
    is( $thx, 1138, 'thx() returns correct value' );
}

done_testing();
