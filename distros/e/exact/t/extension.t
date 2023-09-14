use Test2::V0;

my $version = ( $^V =~ /v\d+\.(\d+)/ ) ? $1 : 0;

SKIP: {
    skip( "Perl $^V does not support extensions", 1 ) if ( $version < 14 );

    BEGIN {
        package exact::____test;

        use exact;

        sub import {
            my ( $self, $params, $caller ) = @_;
            $caller //= caller();
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

    use exact -noautoclean, '____test';

    my $thx = 0;
    ok( lives { $thx = thx() }, 'thx() imported OK' ) or note $@;
    is( $thx, 1138, 'thx() returns correct value' );
}

done_testing;
