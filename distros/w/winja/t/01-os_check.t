use Test::More tests => 2;

# case 1: Fail if OS is not MSWin32
    $^O = 'Unix';
    undef $@;
    eval { require winja };
    ok( $@, 'Load fail if OS is not MSWin32' );
# case 1: Success on MSWin32
    delete $INC{'winja.pm'};
    undef $@;
    $^O = 'MSWin32';
    eval { require winja };
    ok( ! $@, "Load success if OS is MSWin32" );
